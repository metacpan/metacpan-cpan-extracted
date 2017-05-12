package BusyBird::SafeData;
use v5.8.0;
use strict;
use warnings;
use Exporter 5.57 qw(import);
use Data::Diver ();

our @EXPORT_OK = qw(safed);

sub new {
    my ($class, $data) = @_;
    return bless \$data, $class;
}

sub safed {
    return __PACKAGE__->new(@_);
}

sub original {
    return ${shift()};
}

sub val {
    my ($self, @path) = @_;
    return scalar(Data::Diver::Dive($$self, map { "$_" } @path));
}

sub array {
    my ($self, @path) = @_;
    my $val = $self->val(@path);
    if(ref($val) eq 'ARRAY') {
        return @$val;
    }else {
        return ();
    }
}

1;

=pod

=head1 NAME

BusyBird::SafeData - a wrapper of a complex data structure to access its internals safely

=head1 SYNOPSIS

    use BusyBird::SafeData qw(safed);
    
    my $data = {
        foo => {
            bar => [
                0, 1, 2
            ],
            buzz => { hoge => 100 }
        }
    };
    
    my $sd = safed($data);
    
    $sd->original; ## => $data
    
    $sd->val("foo", "bar", 1);              ## => 1
    $sd->val("foo", "buzz", "FOO");         ## => undef
    $sd->val("foo", "quux", "hoge");        ## => undef (and no autovivification)
    $sd->val("foo", "bar", "FOO");          ## => undef (and no exception thrown)
    $sd->val("foo", "buzz", "hoge", "FOO"); ## => undef (and no exception thrown)
    
    $sd->array("foo", "bar");    ## => (0, 1, 2)
    $sd->array("foo", "buzz");   ## => ()
    $sd->array("foo", "bar", 1); ## => ()

=head1 DESCRIPTION

L<BusyBird::SafeData> is a wrapper around a complex data structure to provide a safe way to access its internal data.

=head1 EXPORTABLE FUNCTIONS

The following function is exported only by request.

=head2 $sd = safed($data)

Same as C<< BusyBird::SafeData->new($data). >>

=head1 CLASS METHODS

=head2 $sd = BusyBird::SafeData->new($data)

The constructor.

C<$data> is any scalar. C<$sd> wraps the given C<$data>.

=head1 OBJECT METHODS

=head2 $data = $sd->original()

Returns the original C<$data> that C<$sd> wraps.

=head2 $val = $sd->val(@path)

Return the value specified by C<@path> from C<$sd>.

C<@path> is a list of indices/keys from the root of the C<$sd> down to the value you want.
If it cannot traverse C<@path> completely, it returns C<undef>.

This method never autovivifies anything in C<$sd>.

=head2 @vals = $sd->array(@path)

Return the list of values in the array-ref specified by C<@path>.
If it cannot traverse C<@path> completely, it returns an empty list.
If the value at the C<@path> is not an array-ref, it returns an empty list.

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut
