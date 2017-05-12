package CatalystX::Resource::TraitFor::Controller::Resource::MergeUploadParams;
$CatalystX::Resource::TraitFor::Controller::Resource::MergeUploadParams::VERSION = '0.02';
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

# ABSTRACT: merge upload params into request params

requires qw/
    form
/;


before 'form' => sub {
    my ( $self, $c, $activate_fields ) = @_;

    # for each upload put the Catalyst::Request::Upload object into $params
    if ( $c->req->method eq 'POST' ) {
        while (my ($param_name, $upload) = each %{$c->req->uploads}) {
            $c->req->params->{$param_name} = $upload;
        }
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Resource::TraitFor::Controller::Resource::MergeUploadParams - merge upload params into request params

=head1 VERSION

version 0.02

=head1 METHOD MODIFIERS

=head2 before 'form'

merge $c->req->uploads into $c->req->params

Makes Catalyst::Request::Upload objects available in
HTML::FormHandler::params

You might need this if you are using HTML::FormHandler
and DBIx::Class::InflateColumn::FS

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
