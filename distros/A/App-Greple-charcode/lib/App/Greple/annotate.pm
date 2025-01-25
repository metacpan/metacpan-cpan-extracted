package App::Greple::annotate;

use 5.024;
use warnings;
use utf8;

our $VERSION = "0.9901";

=encoding utf-8

=head1 NAME

App::Greple::annotate - greple module for generic annotation

=head1 SYNOPSIS

B<greple> B<-Mannotate> ...

=head1 VERSION

Version 0.9901

=head1 DESCRIPTION

C<App::Greple::annotate> module is made for C<App::Greple::charcode>
to display annotation for each matched text in the following style.

    $ greple -Mcharcode '\P{ASCII}' charcode.pm

            ┌───  12 \x{fe0e} \N{VARIATION SELECTOR-15}
            │ ┌─  14 \x{a9} \N{COPYRIGHT SIGN}
            │ ├─  14 \x{fe0e} \N{VARIATION SELECTOR-15}
    Copyright︎ ©︎ 2025 Kazumasa Utashiro.

=for html<p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ka-ko.png">
</p>

=head1 MODULE OPTIONS

=over 7

=item B<--align>=I<column>

Align annotation messages.  Defaults to C<1>, which aligns to the
rightmost column; C<0> means no align; if a value of C<2> or greater
is given, it aligns to that numbered column.

=back

=head1 VARIABLES

=over 7

=item B<$App::Greple::annotate::ANNOTATE>

Hold function reference to produce annotation text.  Default function
is declared as this:

    our $ANNOTATE //= sub {
        my %param = @_;
        my($column, $str) = @param{qw(column match)};
        sprintf("%3d %s", $column, $str);
    };

Parameter is passed by C<column> and C<match> labeled list.

=back

=head1 CONFIGURATION

Configuration parameters can be set in several ways.

=head2 MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mannotate::config(align=0)

    greple -Mannotate::config=align=80

=head2 PRIVATE MODULE OPTION

Module-specific options are specified between C<-Mannotate> and C<-->.

    greple -Mannotate --config align=80 -- ...

    greple -Mannotate --align=80 -- ...

=head1 CONFIGURATION PARAMETERS

=over 7

=item B<align>

(default 1) Align the description on the rightmost column, or numbered
column if the value is greater than 2.

=back

=head1 INSTALL

cpanm -n B<App::Greple::annotate>

=head1 SEE ALSO

L<App::Greple>

L<App::Greple::charcode>

=head1 LICENSE

Copyright︎ ©︎ 2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

use Getopt::EX::Config qw(config);
use Hash::Util qw(lock_keys);

our $config = Getopt::EX::Config->new(
    align => 1,
);
my %type = ( align => '=i', '*' => '!' );
lock_keys %{$config};

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with(
	$argv,
	(
	    map {
		my $type = $type{$_} // $type{'*'};
		( $_.$type => ref $config->{$_} ? $config->{$_} : \$config->{$_} ) ;
	    }
	    keys %{$config}
	),
    );
}

use Text::ANSI::Fold::Util qw(ansi_width);
Text::ANSI::Fold->configure(expand => 1);
*vwidth = \&ansi_width;

package Local::Annon {
    sub new {
	my $class = shift;
	@_ == 3 or die;
	bless [ @_ ], $class;
    }
    sub start         { shift->[0] }
    sub end           { shift->[1] }
    sub annon :lvalue { shift->[2] }
}

our $ANNOTATE //= sub {
    my %param = @_;
    my($column, $str) = @param{qw(column match)};
    sprintf("%3d %s", $column, $str);
};

sub prepare {
    our @annotation;
    my $grep = shift;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	my @slice = $grep->slice_result($r);
	my $start = 0;
	my $progress = '';
	my $indent = '';
	my @annon;
	while (my($i, $slice) = each @slice) {
	    next if $slice eq '';
	    my $end = vwidth($progress . $slice);
	    my $gap = $end - $start;
	    my $indent_mark = '';
	    if ($i % 2) {
		my $match = $match[$i / 2];
		$indent_mark = '│';
		my $head = '┌';
		if ($gap == 0) {
		    if (@annon > 0 and $annon[-1]->end == $start) {
			$head = '├';
			$start = $annon[-1]->start;
			substr($indent, $start) = '';
		    } elsif ($start > 0) {
			$start = vwidth($progress =~ s/\X\z//r);
			substr($indent, $start) = '';
		    }
		}
		my $out = sprintf("%s%s─ %s",
				  $indent,
				  $head,
				  $ANNOTATE->(column => $start, match => $slice));
		push @annon, Local::Annon->new($start, $end, $out);
	    }
	    $indent .= sprintf("%-*s", $end - $start, $indent_mark);
	    $progress .= $slice;
	    $start = $end;
	}
	@annon or next;
	if ((my $align = $config->{align}) and (my $max_pos = $annon[-1][0])) {
	    $max_pos = $align if $align > 1;
	    for (@annon) {
		if ((my $extend = $max_pos - $_->[0]) > 0) {
		    $_->annon =~ s/(?=([─]))/$1 x $extend/e;
		}
	    }
	}
	push @annotation, map $_->annon, @annon;
    }
}

sub annotate {
    our @annotation;
    say shift(@annotation) if @annotation > 0;
    undef;
}

1;

__DATA__

option default \
    --postgrep '&__PACKAGE__::prepare' \
    --callback '&__PACKAGE__::annotate'

option --annotate::config \
    --prologue &__PACKAGE__::config($<shift>)

option --config --annotate::config
