=encoding utf8

=head1 NAME

subst::Dict - Dictionary object for App::Greple::subst

=cut

package App::Greple::subst::Dict {

    use v5.14;
    use warnings;
    use utf8;
    use open IO => ':utf8', ':std';
    use Encode qw(encode decode);
    use Data::Dumper;

    use Mo qw(default build); {
	has VERSION => ;
	has NAME    => ;
	has FILE    => ;
	has DATA    => ;
	has LIST    => default => [] ;
	has CONFIG  => default => {} ;
	sub BUILD {
	    my($obj, $args) = @_;
	    if (my $file = $obj->FILE) {
		$obj->read_file($file);
	    }
	    elsif (my $data = $obj->DATA) {
		$obj->read_data($data);
	    }
	}
    } no Mo;

    sub words {
	my $obj = shift;
	@{$obj->LIST};
    }

    sub add {
	my $obj = shift;
	push @{$obj->LIST}, App::Greple::subst::Dict::Ent->new(@_);
	$obj;
    }

    sub add_comment {
	my $obj = shift;
	push @{$obj->LIST}, App::Greple::subst::Dict::Ent->new_comment(@_);
	$obj;
    }

    sub read_data {
	my $obj = shift or die;
	my $data = shift;
	$obj->NAME("DATA");
	if (utf8::is_utf8 $data) {
	    $data = encode 'utf8', $data;
	}
	open my $fh, "<", \$data;
	$obj->read_fh($fh);
	$obj;
    }

    sub read_file {
	my $obj = shift or die;
	my $file = shift;
	$obj->FILE($file);
	$obj->NAME($file =~ s[.*/][]r);
	say $file if $obj->CONFIG->{dictname};
	open my $fh, "<", $file or die "$file: $!\n";
	$obj->read_fh($fh);
	$obj;
    }

    use App::Greple::Pattern;

    sub read_fh {
	my $obj = shift or die;
	my $conf = $obj->CONFIG;
	my $fh = shift;
	local $_;
	my $flag = FLAG_REGEX;
	$flag |= FLAG_COOK if $conf->{linefold};
	while (<$fh>) {
	    chomp;
	    say if $conf->{printdict};
	    if (not /^\s*[^#]/) {
		$obj->add_comment($_);
		next;
	    }
	    my @param = grep { not m{^//+$} } split ' ';
	    splice @param, 0, -2; # leave last one or two
	    my($pattern, $correct) = @param;
	    $obj->add($pattern, $correct, flag => $flag);
	}
	$obj;
    }

    use Text::VisualWidth::PP;
    use Text::VisualPrintf qw(vprintf vsprintf);

    sub vwidth {
	if (not defined $_[0] or length $_[0] == 0) {
	    return 0;
	}
	Text::VisualWidth::PP::width $_[0];
    }

    sub print {
	use List::Util qw(max);
	my $obj = shift;
	my @words = $obj->words;
	my $max = max map { vwidth $_->string  } grep { defined } @words;
	for my $p (@words) {
	    if ($p->is_comment) {
		say $p->comment;
	    } else {
		my($from_re, $to) = ($p->string, $p->correct // '');
		vprintf "%-*s // %s", $max, $from_re // '', $to // '';
		CORE::print "\n";
	    }
	}
    }

    sub to_text {
	my $obj = shift;
	my $text;
	open my $fh, ">:encoding(utf8)", \$text or die;
	select do {
	    my $old = select $fh;
	    $obj->print;
	    close $fh;
	    $old;
	};
	decode 'utf8', $text;
    }

    sub select {
	my $obj = shift;
	my $select = shift;
	my $max = @$obj;
	use Getopt::EX::Numbers;
	my $numbers = Getopt::EX::Numbers->new(max => $max);
	my @select = do {
	    map  { $_ - 1 }
	    sort { $a <=> $b }
	    grep { $_ <= $max }
	    map  { $numbers->parse($_)->sequence }
	    split /,/, $select;
	};
	@$obj = do {
	    my @tmp = (undef) x $max;
	    @tmp[@select] = @{$obj}[@select];
	    @tmp;
	};
	$obj;
    }

}

package App::Greple::subst::Dict::Ent {

    use v5.14;
    use warnings;

    use Exporter 'import';
    our @EXPORT_OK = qw(print_dict);

    use Carp;
    use Getopt::EX::Module;
    use App::Greple::Common;
    use App::Greple::Pattern;

    our @ISA = 'App::Greple::Pattern';

    sub new {
	my $class = shift;
	if (@_ < 2) {
	    return bless {}, $class;
	}
	my($pattern, $correct) = splice @_, 0, 2;
	my $obj = $class->SUPER::new($pattern, @_);
	$obj->correct($correct);
	$obj;
    }

    sub correct {
	my $obj = shift;
	@_ ? $obj->{CORRECT} = shift : $obj->{CORRECT};
    }

    sub new_comment {
	my $class = shift;
	my $comment = shift;
	my $obj = $class->SUPER::new();
	$obj->comment($comment);
	$obj;
    }

    sub comment {
	my $obj = shift;
	@_ ? $obj->{COMMENT} = shift : $obj->{COMMENT};
    }

    sub is_comment {
	my $obj = shift;
	defined $obj->{COMMENT};
    }

}

1;
