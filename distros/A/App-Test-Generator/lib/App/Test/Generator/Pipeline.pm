package App::Test::Generator::Pipeline;

use strict;
use warnings;

use App::Test::Generator::SchemaExtractor;
use App::Test::Generator::TestWriter;
use App::Test::Generator::Mutator;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub new {
    my ($class, %args) = @_;

    die "file required" unless $args{file};

    return bless {
        file         => $args{file},
        test_dir     => $args{test_dir} || 't',
        min_score    => $args{min_score} || 0,
        auto_improve => $args{auto_improve} || 0,
        verbose      => $args{verbose} || 0,
    }, $class;
}
