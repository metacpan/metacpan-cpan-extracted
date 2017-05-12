package Archive::Cpio::File;

sub new {
    my ($class, $val) = @_;

    bless $val, $class;
}

sub name { my ($o) = @_; $o->{name} }
sub size { my ($o) = @_; length($o->{data}) }
sub get_content { my ($o) = @_; $o->{data} }

1;
