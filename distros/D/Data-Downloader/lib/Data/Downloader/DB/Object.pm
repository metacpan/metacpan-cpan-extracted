=head1 Data::Downloader::DB::Object

Base class for Data::Downloader objects.

Inherits from Rose::DB::Object

=head1 METHODS

=over

=cut

package Data::Downloader::DB::Object;

use base qw/Rose::DB::Object/;
use Log::Log4perl qw/:easy/;
use YAML::XS qw/Dump/;

=item init_db

Gets the database handle.

=cut

sub init_db { Data::Downloader::DB->new_or_cached("main") }

=item as_hash

Dump it as a hash of column name -> value pairs

Arguments: skip_re : a regex of column names to skip

=cut

sub as_hash {
    my $self = shift;
    my %args = @_;
    my $skip_re = $args{skip_re};
    return {
        map {
            my $accessor = $_->accessor_method_name;
            my $value = scalar($self->$accessor);
            $value = $value->iso8601 if ref $value eq 'DateTime';
            $skip_re && $accessor =~ /$skip_re/ ? () : (scalar($_) => $value)
        } $self->meta->columns
    }
};

=item dump

Dump a bunch of info about this object.

The info is printed as YAML to STDOUT.

Arguments: skip_re : a regex of column names to skip

=cut

sub dump {
    my $self = shift;
    my %args = @_;
    my $skip_re = $args{skip_re};
    my $h = $self->as_hash(@_);
    for my $r ($self->meta->relationships) {
        next unless $r->type eq 'one to many';
        # TODO other types too, but avoid infinite recursion
        my $method = $r->name;
        next if $skip_re && $method =~ qr/$skip_re/;
        $h->{$r->name} = [ map $_->as_hash(@_), @{ $self->$method } ];
    }
    print Dump($h);
}

=back

=head1 SEE ALSO

L<Rose::DB::Object>

=cut

1;



