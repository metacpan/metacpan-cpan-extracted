package AWS::Lambda::Quick::Processor;
use Mo qw( default required );

our $VERSION = '1.0002';

use AWS::Lambda::Quick::CreateZip ();
use AWS::Lambda::Quick::Upload    ();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

has name         => required => 1;
has src_filename => required => 1;

has 'description';
has 'extra_files';
has 'extra_layers';
has 'memory_size';
has 'region';
has 'stage_name';
has 'timeout';

has _tempdir => sub {
    return tempdir( CLEANUP => 1 );
};
has zip_filename => sub {
    return path( shift->_tempdir, 'handler.zip' );
};

sub selfkv {
    my $self = shift;
    my @computed_args;
    for my $key (@_) {
        my $val = $self->$key;
        push @computed_args, $key => $val if defined $val;
    }
    return @computed_args;
}

sub process {
    my $self = shift;

    AWS::Lambda::Quick::CreateZip->new(
        $self->selfkv(
            qw(
                extra_files
                src_filename
                zip_filename
                )
        ),
    )->create_zip;

    my $uploader = AWS::Lambda::Quick::Upload->new(
        $self->selfkv(
            qw(
                description
                extra_layers
                memory_size
                name
                region
                stage_name
                timeout
                zip_filename
                )
        ),
    );

    if ( $ENV{AWS_LAMBDA_QUICK_UPDATE_CODE_ONLY} ) {
        $uploader->just_update_function_code;
        return q{};
    }

    $uploader->upload;
    return $uploader->api_url;
}

1;

__END__

=head1 NAME

AWS::Lambda::Quick::Processor - main object class for AWS::Lambda::Quick

=head1 DESCRIPTION

No user servicable parts.  See L<AWS::Lambda::Quick> for usage.

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2019.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AWS::Lambda::Quick>

=cut
