use File::Basename qw(dirname);
use File::Spec::Functions;
use lib catdir(dirname($0), 'lib');

# add your local modules here...

my $app = sub {
    my $self = shift;
    my $body = 'Hello world!'; 
    [200, ['Content-Type' => 'text/plain'], [ $body ]];
};
