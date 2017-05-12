package Class::PObject::Test;

# Test.pm,v 1.5 2005/02/20 18:05:00 sherzodr Exp

use strict;
#use diagnostics;
use Carp;
use Class::PObject;
use vars ('$VERSION');

$VERSION = '1.02';

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my $self = bless {
        driver      => $_[0], # || 'file',
        datasource  => $_[1] # || 'data'
    }, $class;

    unless ( $self->{driver} && $self->{datasource} ) {
        croak "'driver' and 'datasource' are not set in the test script";
    }
    return $self;
}


sub run {
    my $self = shift;

    croak "You should override run() method in your test class";

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Test - Base test framework for Class::PObject drivers

=head1 SYNOPSIS

    package Class::PObject::Test::MyTest;
    require Class::PObject::Test;
    @ISA = ('Class::PObject::Test');

    sub run {
        my $self = shift;

        my $driver      = $self->{driver};
        my $datasource  = $self->{datasource};

        # perform your tests using $driver and $datasource

    }

=head1 ABSTRACT

    Class::PObject::Test is a base testing framework for Class::PObject drivers.

=head1 DESCRIPTION

Class::PObject::Test is used as a base class by test libraries, and provides
two methods, C<new()> and C<run()>. Subclasses of Class::PObject::Test are
expected to override C<run()>.

=head2 IS THIS WAY OF TESTING NECESSARY

Same sets of tests must be performed for every single driver available to ensure
all the drivers are compatible. That's why, instead of putting redundant chunks of
codes in multiple F<t/*.t> files, we created a library, which can run same
tests for different drivers.

For example, to run some basic/core tests on C<file> driver, we do:

    # t/01basic_file.t
    use Class::PObject::Test::Basic;
    $t = new Class::PObject::Test::Basic('file', './data');
    $t->run()

To run these same set of tests for F<mysql> driver, for example, we can do:

    # t/02basic_mysql.t
    use Class::PObject::Test::Basic;
    $t = new Class::PObject::Test::Basic('mysql', {Handle=>$dbh});
    $t->run()

and so on.

This will ensure that same exact tests are run for every driver.

=head1 METHODS

=over 4

=item *

C<new($driver, $datasource)> - constructor method. Accepts two arguments,
I<$driver> and I<$datasource>. You can access these object attributes from within
C<run()> to generate I<pobjects> for testing purposes.

=item *

C<run()> - runs the tests. You can use L<Test::More> - testing library for running the tests.
A very simple test can look like:

    sub run {
        my $self = shift;

        pobject ClassName => {
            columns => ['id', 'a', 'b', 'c'],
            driver  => $self->{driver},
            datasource => $self->{datasource}
        };
        ok(1);

        my $obj = ClassName->new();
        ok($obj);

        $obj->a('A');
        $obj->b('B');

        ok($obj->save)
    }

If you want to write a special test library, you are expected to do a little more than that,
because L<Class::PObject::Test::Basic> already performs most of the L<Class::PObject> driver
functionality.

=back

=head1 SEE ALSO

L<Class::PObject::Test::Basic>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
