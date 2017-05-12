package Acme::Incorporated;

use strict;
use IO::File;
use File::Spec;

use vars '$VERSION';
$VERSION = '1.00';

sub import
{
	unshift @INC, \&fine_products;
}

sub fine_products
{
	my ($code, $module) = @_;
	(my $modfile        = $module . '.pm') =~ s{::}{/}g;
	my $fh              = bad_product()->( $module, $modfile );

	return unless $fh;

	$INC{$modfile} = 1;
	$fh->seek( 0, 0 );

	return $fh;
}

sub empty_box
{
	my ($module, $modpath) = @_;

	return _fake_module_fh(<<END_MODULE);
package $module;

sub DESTROY {}

sub AUTOLOAD
{
	return 1;
}

1;
END_MODULE

}

sub breaks_when_needed
{
	my ($module, $modfile) = @_;

	my    $file;
	local @INC = @INC;

	for my $path (@INC)
	{
		local @ARGV = File::Spec->catfile( $path, $modfile );
		next unless -e $ARGV[0];

		$file = do { local $/; <> } or return;
	}

	return unless $file;

	$file =~ s/(while\s*\()/$1 Acme::Incorporated::breaks() && /g;
	$file =~ s[(for[^;]+{)(\s*)]
		      [$1$2last unless Acme::Incorporated::breaks();$2]xsg;

	return _fake_module_fh( $file );
}

sub out_of_stock
{
	my ($module, $modfile) = @_;

	return _fake_module_fh(<<END_MODULE);
print "$module is out of stock at the moment.\n"
delete \$INC{$modfile};
END_MODULE

}

sub _fake_module_fh
{
	my $text = shift;
	my $fh   = IO::File->new_tmpfile() or return;

	$fh->print( $text );
	$fh->seek( 0, 0 );

	return $fh;
}

sub bad_product
{
	my $weight = rand();

	return \&empty_box          if $weight <= 0.10;
	return \&breaks_when_needed if $weight <= 0.20;
	return \&out_of_stock       if $weight <= 0.30;

	return sub {};
}

sub breaks
{
	return rand() <= 0.10;
}

1;
__END__

=head1 NAME

Acme, Inc. produces fine and wonderful products for your pleasure. 

=head1 SYNOPSIS

  use Acme::Incorporated;

  # your code as normal

=head1 DESCRIPTION

Acme, Inc. produces fine and wonderful products for your pleasure.  We have a
huge catalog of products for your enjoyment, including many CPAN modules.
Remember to go to Acme, Inc. first.

=head1 USAGE

Just use Acme::Incorporated before any other Perl module and we'll rush our
version right to you at the right price and at the right time.

B<WARNING>  Supplies are limited.  Please act fast.  Some modules may be
unavailable.

=head1 FUNCTIONS

You should never have to know how we at Acme, Incorporated do what we do, but
recently people have raised questions about the reliability of our products.
We strive for transparency in our work and have nothing to fear from your
scrutiny.  Our main magic comes from the function:

=over 4

=item C<fine_products>

Here we recognize your need for an external product and rush to fulfill your
order immediately.

=back

=head1 BUGS

As you'd expect.

Some of our competitors, being the jealous types, and some troublemakers,
having nothing better to do, claim that our fulfillment and quality assurance
departments are full of errors.  We disclaim this, specifically in five parts:

=over 4

=item C<bad_product>

Some people claim that we ship bad products, up to 30% of the time.  This is
not true.  All of our products work exactly as we have designed them to work.
Any error rests with the user, or more likely a competing product clever
disguised as ours.

=item C<breaks>

Another claim is that our work breaks up to 10% of the time.  This is a lie
that we shall not dignify any further.

=item C<breaks_when_needed>

The third claim is that our products somehow detect your hour of need and
suddenly fail to work immediately.  This is clearly a coincidence; our minds
love to see patterns even when they are not present.  Think of all of the times
ourproducts have worked perfectly and you will see that, even if our products
ever broke, you merely see coincidences.

=item C<empty_box>

One particularly disturbing claim is that we occasionally ship empty boxes.  If
this ever happens, please return the box for a full one.

=item C<out_of_stock>

It's true; sometimes a product proves so popular that we temporarily run out of
stock.  In this case, we will ship you a raincheck to redeem when we can finish
fulfilling your order.  It's important to us to give you your product as soon
as possible -- perhaps even sooner than we have it!

=back

=head1 SUPPORT

We're so sure you'll be pleased that we offer a satisfaction-guaranteed
money-back guarantee.  (Some restrictions apply.)

=head1 AUTHOR

	chromatic
	chromatic@wgz.org
	http://wgz.org/chromatic/

You should also blame people like Mark Fowler, Leon Brocard, James Duncan, and
Adam Turoff who were there at the time and did nothing to dissuade me.

=head1 COPYRIGHT

Copyright (c) 2003, 2005 chromatic.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license is in the F<LICENSE> file included with this
module.

=head1 SEE ALSO

perl(1).
