package ByteBeat;
our $VERSION = '0.0.4';

use Mo;
use Getopt::Long;
use ByteBeat::Compiler;

has args => ();

my $code = '';
my $file;
my $second = 2**13;
my $length = 0;
my $debug = 0;
my $shell = 0;
my $play = 0;

sub run {
    my ($self) = shift;
    $self->get_options;

    if ($shell or not $code) {
        require ByteBeat::Shell;
        ByteBeat::Shell->new(file => $file)->run;
        return;
    }

    my $function = ByteBeat::Compiler->new(code => $code)->compile;

    if ($debug) {
        print "RPN: @{$function->{rpn}}\n";
        for (my $t = 1; $t <= $length; $t++) {
            print $function->run($t) % 256, "\n";
        }
        return;
    }

    $length ||= 60 * $second;

    if ($play) {
        require IPC::Run;
        my $bytes;
        my $out;

        my $process = IPC::Run::start(['aplay'], \$bytes, \$out, \$out);
        for (my $t = 1; $t <= $length; $t++) {
            $bytes .= chr ($function->run($t) % 256);
            IPC::Run::pump($process);
        }
    }

    for (my $t = 1; $t <= $length; $t++) {
        print chr ($function->run($t) % 256);
    }
}

sub get_options {
    my ($self) = shift;
    local @ARGV = @{$self->args};
    GetOptions(
        'file=s' => \$file,
        'length=s' => \$length,
        'debug' => \$debug,
        'shell' => \$shell,
        'play' => \$play,
    );
    $length =
        $length =~ /^(\d+)s$/ ? $1 * $second :
        $length =~ /^(\d+)m$/ ? $1 * $second * 60 :
        $length =~ /^(\d+)$/ ? $1 :
            die "Invalid value for '-l'\n";
    $code = @ARGV ? shift(@ARGV) : -t STDIN ? '' : <>;
    chomp $code;
}

1;
