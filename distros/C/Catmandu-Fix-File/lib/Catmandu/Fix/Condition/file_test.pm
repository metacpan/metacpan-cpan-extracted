package Catmandu::Fix::Condition::file_test;
use Catmandu::Sane;
use Moo;
use Carp qw(confess);
use Catmandu::Util qw();
use namespace::clean;
use Catmandu::Fix::Has;

my $allowed_tests = [qw(r w o x R W O X e z s f d l p S b c t u g k B)];

has path  => (fix_arg => 1);
has test => (fix_arg => 1);
has _tests => ( is => 'ro', lazy => 1, builder => '_build_tests' );

sub _build_tests {
    my $self = $_[0];
    my @vals = split( //o, $self->test );
    my $tests = [
        grep { Catmandu::Util::array_includes( $allowed_tests, $_ ) or confess("invalid test $_"); } @vals
    ];
    unless( @$tests ){
        confess "no valid tests supplied";
    }
    $tests;
}

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var, $fixer) = @_;
    my $tests = join(' && ',map { "-$_ ${var}" } @{$self->_tests()});
    "(is_value( ${var} ) ? $tests : 0)"
}

=head1 NAME

Catmandu::Fix::Condition::file_test - only execute fixes of file test is successfull

=head1 SYNOPSIS

    add_field('path','/home/njfranck')

    if file_test('path','dw')
        add_field('messages.$append','path is a directory')
        add_field('messages.$append','path is writable')
    end

=head1 ARGUMENTS

=over

=item path

=item tests

List of file tests, all in one string.

Possible file tests (taken from <http://perldoc.perl.org/functions/-X.html>):

R  File is readable by real uid/gid.

W  File is writable by real uid/gid.

X  File is executable by real uid/gid.

O  File is owned by real uid.

e  File exists.

z  File has zero size (is empty).

s  File has nonzero size (returns size in bytes).

f  File is a plain file.

d  File is a directory.

l  File is a symbolic link (false if symlinks aren't supported by the file system).

p  File is a named pipe (FIFO), or Filehandle is a pipe.

S  File is a socket.

b  File is a block special file.

c  File is a character special file.

t  Filehandle is opened to a tty.

u  File has setuid bit set.

g  File has setgid bit set.

k  File has sticky bit set.

T  File is an ASCII or UTF-8 text file (heuristic guess).

B  File is a "binary" file (opposite of -T).

=back

=head1 AUTHOR

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
