package App::diff2vba;
use 5.014;
use warnings;

our $VERSION = "1.00";

use utf8;
use Encode;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}
use open IO => 'utf8', ':std';
use Pod::Usage;
use Data::Section::Simple qw(get_data_section);
use List::Util qw(max);
use List::MoreUtils qw(pairwise);
use App::diff2vba::Util qw(split_string);
use App::sdif::Util qw(read_unified_2);

use Getopt::EX::Hashed 1.03; {

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'ro' ] );

    has debug     => "      " ;
    has verbose   => " v !  " , default => 1;
    has format    => "   =s " , default => 'dumb';
    has subname   => "   =s " , default => 'Patch';
    has maxlen    => "   =i " , default => 250;
    has adjust    => "   =i " , default => 2;
    has identical => "   !  " ;
    has reverse   => "   !  " ;
    has help      => "      " ;
    has version   => "      " ;

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	print "Version: $VERSION\n";
	exit;
    };

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

    has SCRIPT    => ;
    has TABLE     => ;
    has QUOTES    => default => { '“' => "Chr(&H8167)", '”' => "Chr(&H8168)" };
    has QUOTES_RE => ;

} no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;

    use Getopt::EX::Long qw(GetOptions Configure ExConfigure);
    ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
    Configure qw(bundling no_getopt_compat);
    $app->getopt || pod2usage();

    $app->initialize;

    for my $file (@ARGV ? @ARGV : '-') {
	print $app->reset->load($file)->vba->script;
    }

    return 0;
}

sub load {
    my $app = shift;
    my $file = shift;

    open my $fh, $file or die "$file: $!\n";

    $app->TABLE(my $fromto = []);
    while (<$fh>) {
	#
	# diff --combined (generic)
	#
	if (m{^
	       (?<command>
	       (?<mark> \@{2,} ) [ ]
	       (?<lines> (?: [-+]\d+(?:,\d+)? [ ] ){2,} )
	       \g{mark}
	       (?s:.*)
	       )
	       }x) {
	    my($command, $lines) = @+{qw(command lines)};
	    my $column = length $+{mark};
	    my @lines = map {
		$_ eq ' ' ? 1 : int $_
	    } $lines =~ /\d+(?|,(\d+)|( ))/g;

	    warn $_ if $app->debug;

	    next if @lines != $column;
	    next if $column != 2;

	    push @$fromto, $app->read_diff($fh, @lines);
	}
    }
    $app;
}

sub vba {
    (my $app = shift)
	->prologue()
	->substitute()
	->epilogue();
}

sub prologue {
    my $app = shift;
    if (my $name = $app->subname) {
	$app->append(text => "Sub $name()\n");
    }
    $app->append(section => "setup.vba");
    $app;
}

sub epilogue {
    my $app = shift;
    if (my $name = $app->subname) {
	$app->append(text => "End Sub\n");
    }
    $app;
}

sub substitute {
    my $app = shift;
    my $template = sprintf "subst_%s.vba", $app->format;
    my $max = $app->maxlen;

    my @fromto = do {
	if ($app->reverse) {
	    map { [ $_->[1], $_->[0] ] } @{$app->TABLE};
	} else {
	    @{$app->TABLE};
	}
    };
    while (my($i, $fromto) = each @fromto) {
	my $fromto = $fromto[$i];
	use integer;
	chomp @$fromto;
	my($from, $to) = @$fromto;
	my $longer = max map { length } $from, $to;
	my $count = ($longer + $max - 1) / $max;
	my @from = split_string($from, $count);
	my @to   = split_string($to,   $count);
	adjust_border(\@from, \@to, $app->adjust) if $app->adjust;
	for my $j (keys @from) {
	    next if !$app->identical and $from[$j] eq $to[$j];
	    $app->append(text => sprintf "' # %d-%d\n", $i + 1, $j + 1);
	    $app->append(section => $template,
			 { TARGET      => $app->string_literal($from[$j]),
			   REPLACEMENT => $app->string_literal($to[$j]) });
	}
    }
    $app;
}

sub initialize {
    my $app = shift;
    my $chrs = join '', keys %{$app->QUOTES};
    $app->QUOTES_RE(qr/[\Q$chrs\E]/);
    $app;
}

sub append {
    my $app = shift;
    my $what = shift // 'text';
    if      ($what eq 'text') {
	push @{$app->SCRIPT}, @_;
    } elsif ($what eq 'section') {
	push @{$app->SCRIPT}, $app->section(@_);
    } else { die }
    $app;
}

sub script {
    my $app = shift;
    join "\n", @{$app->SCRIPT};
}

sub reset {
    (my $app = shift)->SCRIPT([]);
    $app;
}

sub section {
    my $app = shift;
    my $section = shift;
    my $replace = shift // {};
    local $_ = get_data_section($section);
    do { s/\A\n*//; s/\n\K\n*\z// };
    for my $name (keys %$replace) {
	s/\b(\Q$name\E)\b/$replace->{$1}/ge;
    }
    $_;
}

sub read_diff {
    my $app = shift;
    my($fh, @lines) = @_;
    my @diff = read_unified_2 $fh, @lines;
    my @out;
    while (my($c, $o, $n) = splice(@diff, 0, 3)) {
	@$o > 0 and @$o == @$n or next;
	s/^[\t +-]// for @$c, @$o, @$n;
	push @out, pairwise { [ $a, $b ] } @$o, @$n;
    }
    @out;
}

sub string_literal {
    my $app = shift;
    my $quotes  = $app->QUOTES;
    my $chrs_re = $app->QUOTES_RE;
    join(' & ',
	 map { $quotes->{$_} || sprintf('"%s"', s/\"/\"\"/gr) }
	 map { split /($chrs_re)/ } @_);
}

######################################################################

sub adjust_border {
    my($a, $b, $max) = @_;
    $max //= 2;
    return if @$a < 1;
    return if $max == 0;
    for my $i (1 .. $#{$a}) {
	next if substr($a->[$i-1], -($max+1)) eq substr($b->[$i-1], -($max+1));
	for my $shift (reverse 1 .. $max) {
	    _adjust($a, $b, $i, $shift) and last;
	    _adjust($b, $a, $i, $shift) and last;
	}
    }
}

sub _adjust {
    my($a, $b, $i, $len) = @_;
    if (substr($a->[$i-1], -($len + 1), $len + 1) eq
	substr($b->[$i-1], -1, 1) . substr($b->[$i], 0, $len)) {
	$b->[$i-1] .= substr($b->[$i], 0, $len, '');
	return 1;
    }
    return 0;
}

1;

=encoding utf-8

=head1 NAME

App::diff2vba - generate VBA patch script from diff output

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

  greple -Mmsdoc -Msubst \
    --all-sample-dict --diff some.docx | diff2vba > patch.vba

=head1 DESCRIPTION

B<diff2vba> is a command to generate VBA patch script from diff output.

Read document in script file for detail.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

@@ setup.vba

With Selection.Find
    .MatchCase = True
    .MatchByte = True
    .IgnoreSpace = False
    .IgnorePunct = False
End With

Options.AutoFormatAsYouTypeReplaceQuotes = False

@@ subst_dumb.vba

With Selection.Find
    .Text             = TARGET
    .Replacement.Text = REPLACEMENT
    .Execute Replace:=wdReplaceOne
End With
Selection.Collapse Direction:=wdCollapseEnd

@@ subst_dumb2.vba

With Selection.Find
    .Text = TARGET
    if .Execute Then
        Selection.Range.Text = REPLACEMENT
    End If
End With

