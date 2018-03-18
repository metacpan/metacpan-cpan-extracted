package Cmd::Dwarf;
our $VERSION = '1.70';
1;
__END__

=encoding utf-8

=head1 NAME

Dwarf - Web Application Framework (Perl5)

=head1 SYNOPSIS

	package App::Controller::Web;
	use Dwarf::Pragma;
	use parent 'App::Controller::WebBase';
	use Dwarf::DSL;

	sub get {
		render 'index.html';
	}

	1;

=head1 DESCRIPTION

https://github.com/seagirl/dwarf

=head1 LICENSE

Copyright (C) Takuho Yoshizu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuho Yoshizu E<lt>yoshizu@s2factory.co.jpE<gt>

=cut
