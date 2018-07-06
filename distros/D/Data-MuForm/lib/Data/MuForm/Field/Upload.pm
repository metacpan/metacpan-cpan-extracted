package Data::MuForm::Field::Upload;
# ABSTRACT: file upload field

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Field';

use Scalar::Util ('blessed');


has min_size   => ( is => 'rw', default => 1 );
has max_size   => ( is => 'rw', default => 1048576 );
sub build_input_type { 'file' }

our $class_messages = {
        'upload_file_not_found' => 'File not found for upload field',
        'upload_file_empty' => 'File uploaded is empty',
        'upload_file_too_small' => 'File is too small (< [_1] bytes)',
        'upload_file_too_big' => 'File is too big (> [_1] bytes)',
};
sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub validate {
    my $self   = shift;

    my $upload = $self->value;
    my $size = 0;
    if( blessed $upload && $upload->can('size') ) {
        $size = $upload->size;
    }
    elsif( is_real_fh( $upload ) ) {
        $size = -s $upload;
    }
    else {
        return $self->add_error($self->get_message('upload_file_not_found'));
    }
    return $self->add_error($self->get_message('upload_file_empty'))
        unless $size > 0;

    if( defined $self->min_size && $size < $self->min_size ) {
        $self->add_error( $self->get_message('upload_file_too_small'), $self->min_size );
    }

    if( defined $self->max_size && $size > $self->max_size ) {
        $self->add_error( $self->get_message('upload_file_too_big'), $self->max_size );
    }
    return;
}

# stolen from Plack::Util::is_real_fh
sub is_real_fh {
    my $fh = shift;

    my $reftype = Scalar::Util::reftype($fh) or return;
    if( $reftype eq 'IO'
            or $reftype eq 'GLOB' && *{$fh}{IO} ){
        my $m_fileno = $fh->fileno;
        return unless defined $m_fileno;
        return unless $m_fileno >= 0;
        my $f_fileno = fileno($fh);
        return unless defined $f_fileno;
        return unless $f_fileno >= 0;
        return 1;
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Field::Upload - file upload field

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This field is designed to be used with a blessed object with a 'size' method,
such as L<Catalyst::Request::Upload>, or a filehandle.
Validates that the file is not empty and is within the 'min_size'
and 'max_size' limits (limits are in bytes).
A form containing this field must have the enctype set.

    package My::Form::Upload;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+enctype' => ( default => 'multipart/form-data');

    has_field 'file' => ( type => 'Upload', max_size => '2000000' );
    has_field 'submit' => ( type => 'Submit', value => 'Upload' );

In your controller:

    my $form = My::Form::Upload->new;
    my $params = $c->req->body_parameters;
    $params->{file} = $c->req->upload('file') if $c->req->method eq 'POST';
    $form->process( params => $params );
    return unless ( $form->validated );

You can set the min_size and max_size limits to undef if you don't want them to be validated.

=head1 DEPENDENCIES

=head2 layout_type

Layout type is 'upload'

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
