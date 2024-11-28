# Copyrights 2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Business::CAMT.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package Business::CAMT::Message;{
our $VERSION = '0.12';
}


use strict;
use warnings;

use Log::Report 'business-camt';
use Scalar::Util  qw/weaken/;
use JSON          ();


sub new
{	my ($class, %args) = @_;
	my $data = delete $args{data} or return undef;
    (bless $data, $class)->init(\%args);
}

sub init($) {
	my ($self, $args) = @_;

	my %attrs;
	$attrs{set}     = $args->{set}     or panic;
	$attrs{version} = $args->{version} or panic;
	$attrs{camt}    = $args->{camt}    or panic;
	weaken $attrs{camt};
	$self->{_attrs} = \%attrs;

	$self;
}


sub _loadSubclass($)
{	my ($class, $set) = @_;
	$class eq __PACKAGE__ or return $class;
	my $super = 'Business::CAMT::CAMT'.($set =~ s/\..*//r);

	# Is there a special implementation for this type?  Otherwise create
	# an empty placeholder.
	no strict 'refs';
	eval "require $super" or @{"$super\::ISA"} = __PACKAGE__;
	$super;
}

sub fromData(%)
{	my ($class, %args) = @_;
	my $set = $args{set} or panic;
	$class->_loadSubclass($set)->new(%args);
}

#-------------------------

sub set     { $_[0]->{_attrs}{set} }
sub version { $_[0]->{_attrs}{version} }
sub camt    { $_[0]->{_attrs}{camt} }

#-------------------------

sub write(%)
{	my ($self, $file) = (shift, shift);
	$self->camt->write($file, $self, @_);
}


sub toPerl()
{	my $self = shift;
	my $attrs = delete $self->{_attrs};

	my $d = Data::Dumper->new([$self], 'MESSAGE');
	$d->Sortkeys(1)->Quotekeys(0)->Indent(1);
	my $text = $d->Dump;

	$self->{_attrs} = $attrs;
	$text;
}


sub toJSON(%)
{	my ($self, %args) = @_;
	my %data  = %$self;        # Shallow copy to remove blessing
	delete $data{_attrs};      # remove object attributes

	my $json     = JSON->new;
	my $settings = $args{settings} || {};
	my %settings = (pretty => 1, canonical => 1, %$settings);
	while(my ($method, $value) = each %settings)
	{	$json->$method($value);
	}
	$json->encode(\%data);     # returns bytes
}

1;
