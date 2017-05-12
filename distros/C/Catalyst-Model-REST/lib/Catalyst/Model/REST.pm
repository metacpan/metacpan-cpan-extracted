package Catalyst::Model::REST;
{
  $Catalyst::Model::REST::VERSION = '0.27';
}

use Moose;

extends 'Catalyst::Model';

with 'Role::REST::Client';


__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Catalyst::Model::REST - REST model class for Catalyst

=head1 VERSION

version 0.27

=head1 SYNOPSIS

Use from a controller

	# model
	__PACKAGE__->config(
		server =>      'http://localhost:3000',
		type   =>      'application/json',
		clientattrs => {timeout => 5},
	);

	# controller
	sub foo : Local {
		my ($self, $c) = @_;
		my $res = $c->model('MyData')->post('foo/bar/baz', {foo => 'bar'});
		my $code = $res->code;
		my $data = $res->data;
		...
	}

For internal use

       # model
       sub model_foo {
               my ($self) = @_;
               my $res = $self->post('foo/bar/baz', {foo => 'bar'});
               my $code = $res->code;
               my $data = $res->data;
               return $data if $code == 200;
       }

=head1 DESCRIPTION

This Catalyst Model class is a thin wrapper over L<Role::REST::Client>

Use this module if you need to talk to a REST server as a separate model.

=head1 NAME

Catalyst::Model::REST - REST model class for Catalyst

=head1 AUTHOR

Kaare Rasmussen, <kaare at cpan dot com>

=head1 BUGS 

Please report any bugs or feature requests to bug-catalyst-model-rest at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-REST.

=head1 COPYRIGHT & LICENSE 

Copyright 2012 Kaare Rasmussen, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
# ABSTRACT: REST model class for Catalyst
