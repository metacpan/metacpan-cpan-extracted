package Dwarf::Plugin::Devel::StackTrace;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Devel::StackTrace;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, stacktrace => sub {
		my ($self, $error) = @_;
		_build_stacktrace($self->is_production, $error);
	});
}

sub _build_stacktrace {
	my ($is_production, $error) = @_;
	$error //= '';

	return '' if $is_production;

	my @frames = Devel::StackTrace->new()->frames;

	$error .= "\n";
	$error .= join "\n", map {
		my $s = $_->subroutine // '';
		$s .= ' at ';
		$s .= $_->filename // '';
		$s .= ' line ';
		$s .= $_->line // '';
		$s .= "\n";
		$s .= _build_context($_);
		$s;
	} @frames[ 1 .. $#frames ];

	return $error;
}

sub _build_context {
    my $frame = shift;
    my $file    = $frame->filename;
    my $linenum = $frame->line;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        open my $fh, '<', $file
            or die "cannot open $file:$!";
        my $cur_line = 0;
        while (my $line = <$fh>) {
            ++$cur_line;
            last if $cur_line > $end;
            next if $cur_line < $start;
            $line =~ s|\t|        |g;
            $code .= sprintf('%5d: %s', $cur_line, $line);
        }
        close $file;
    }
    return $code;
}

1;
