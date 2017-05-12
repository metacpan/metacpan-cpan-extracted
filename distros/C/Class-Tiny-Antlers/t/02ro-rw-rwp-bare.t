=pod

=encoding utf-8

=head1 PURPOSE

Test C<ro>, C<rw>, C<rwp> and C<bare> attributes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

{
	package YYY;
	use Class::Tiny;
	sub ddd { 'inherited sub' };
}

{
	package XXX;
	use Class::Tiny::Antlers;
	
	extends 'YYY';
	
	has aaa => (is => 'ro');
	has bbb => (is => 'rw');
	has ccc => (is => 'rwp');
	has ddd => (is => 'bare');
	has eee => ();  # default should be rw
}

my $obj = new_ok 'XXX' => [ aaa => 11, bbb => 12, ccc => 13, ddd => 14, eee => 15 ];

subtest "ro attribute" => sub {
	is($obj->aaa, 11, 'reader works');
	
	$obj->aaa(21);
	is($obj->aaa, 11, '... and cannot be used as writer');
	
	done_testing;
};

subtest "rw attribute" => sub {
	is($obj->bbb, 12, 'accessor can be used for reading');
	
	$obj->bbb(22);
	is($obj->bbb, 22, '... and writing');
	
	done_testing;
};

subtest "rwp attribute" => sub {
	is($obj->ccc, 13, 'reader works');
	
	$obj->ccc(23);
	is($obj->ccc, 13, '... and cannot be used as writer');
	
	$obj->_set_ccc(23);
	is($obj->ccc, 23, 'private writer works');
	
	done_testing;
};

subtest "bare attribute" => sub {
	is($obj->{ddd}, 14, 'bare attributes accepted by constructor');
	
	is($obj->ddd, 'inherited sub', 'but no methods are generated');
	
	done_testing;
};

subtest "attribute with no `is` option at all" => sub {
	is($obj->eee, 15, 'accessor can be used for reading');
	
	$obj->eee(25);
	is($obj->eee, 25, '... and writing');
	
	done_testing;
};

done_testing;

