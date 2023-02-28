package App::SeismicUnixGui::misc::param;
use Moose;
our $VERSION = '0.0.1';

=head2 initialize shared anonymous hash 

  key/value pairs

=cut

my $param = {
    _file_in  => '',
    _file_out => '',
    _length   => '',
    _path_out => '',
    _outbound => '',
};

=head2 sub file_in
file_out
  print("file_in is $param->{_file_in}\n");
path_out
=cut

sub file_in {
    my ( $self, $file_aref ) = @_;
    $param->{_file_in} = @$file_aref[0];
}

=head2 sub file_out

  print("file_out is $param->{_file_out}\n");

=cut

sub file_out {
    my ( $self, $file_aref ) = @_;
    $param->{_file_out} = @$file_aref[0];
}

=head2 sub path_out

  print("path_out is $param->{_path_out}\n");

=cut

sub path_out {
    my ( $self, $file_aref ) = @_;
    $param->{_path_out} = @$file_aref[0];
}

=head2 sub param_names

  print("param_names is $param->{_param_names}\n");

=cut

sub param_names {
    my ( $self, $names_aref ) = @_;
    $param->{_param_names} = $names_aref;
    print("param,param_names  @{$param->{_param_names}}\n");
    $param->{_length} = scalar @$names_aref;
}

=head2 sub param_values

  print("param_values is $param->{_param_values}\n");

=cut

sub param_values {
    my ( $self, $values_aref ) = @_;
    $param->{_param_values} = $values_aref;
    $param->{_length}       = scalar @$values_aref;
    print("param,param_values @{$param->{_param_values}}\n");
}

=pod sub write 

 open  and write 
 to the file

=cut

sub write {
    my ($self) = shift;

    if ( $param->{_file_out} && $param->{_length} ) {    # avoids errors

        $param->{_outbound} = $param->{_path_out} . $param->{_file_out};

        open my $OUT, '>', $param->{_outbound} or die;

        for ( my $i = 0 ; $i < $param->{_length} ; $i++ ) {
            print $OUT (
"@{$param->{_param_names}}[$i] = @{$param->{_param_values}}[$i]\n"
            );
        }

        close($OUT);
    }

}

1;
