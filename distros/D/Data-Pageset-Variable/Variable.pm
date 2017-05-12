package Data::Pageset::Variable;
$Data::Pageset::Variable::VERSION = '0.03';

use strict;
use warnings;

use base 'Data::Pageset';

use Carp;

=head1 NAME

Data::Pageset::Variable - Variable results on each page of results.

=head1 SYNOPSIS

	use Data::Pageset::Variable;
        	# As Data::Pageset except...

        my $page_info = Data::Pageset->new(
                { 
                        total_entries              => $total_entries, 
                        variable_entries_per_page  => { 1 => 30, 2 => 20, 3 => 10, } 
                        entries_per_page           => 10,
                }
        );

=head1 DESCRIPTION

Data::Pageset is A Great Module, and totally useful. This is a subclass that
extends its behaviour.

Data::Pageset returns an object with a set number of pages per set. The point 
of Data::Pageset::Variable is that you might not want this to be so. You might,
for reasons best known to yourself, want to have twice the number of results on
the first page as on the second, and so on.

So now you can!

=head1 HAIKU

 Different numbers
 Of results on each page helps
 Tabulate results

This arose as Tony (http://www.tmtm.com/nothing/) suggested to me that if I can't 
write the documentation of a module in haiku, then it is doing too many things. 
As I (also) believe that modules should be responsible for one concept, and one only.

Also, I have no poetical ability, so forgive my clumsy attempt.

=head1 METHODS

=head2 variable_entries_per_page

        # In the constructor hashref...
		variable_entries_per_page => { 1 => 30, 2 => 20, 3 => 10, },

The variable_entries_per_page argument takes a hashref. 

The key/value pairs of this hashref are the pages and the number of entries
on the page. If there is a page for which none is specified, then we use the 
value of default_entries_per_page.

If this isn't set, then we behave exactly like Data::Pageset.

=head2 entries_per_page

	# In the constructor hashref...  
		entries_per_page => 10,

This must be set. It is not optional. This is the number of entries per page
for all pages which aren't specified in the entries_per_page hashref.
            
=cut         

sub new {
	my ($proto,$conf) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	
	croak "total_entries and entries_per_page must be supplied" 
		unless defined $conf->{'total_entries'} && defined $conf->{'entries_per_page'};

	$conf->{'current_page'} = 1 unless defined $conf->{'current_page'};

	if (exists $conf->{'variable_entries_per_page'} && ref $conf->{'variable_entries_per_page'} ne 'HASH') {
		croak "variable_entries_per_page must be a hashref";
	}

	$self->{vari_pages} = $conf->{'variable_entries_per_page'} || {};

	$self->{TOTAL_ENTRIES}    = $conf->{'total_entries'};
	$self->{ENTRIES_PER_PAGE} = $conf->{'entries_per_page'};
	$self->{CURRENT_PAGE}     = $conf->{'current_page'};

	bless($self, $class);
	
	croak("Fewer than one entry per page!") if $self->entries_per_page < 1;
	$self->{CURRENT_PAGE} = $self->first_page unless defined $self->current_page;
	$self->{CURRENT_PAGE} = $self->first_page if $self->current_page < $self->first_page;
	$self->{CURRENT_PAGE} = $self->last_page if $self->current_page > $self->last_page;

	$self->pages_per_set($conf->{'pages_per_set'}) if defined $conf->{'pages_per_set'};

	return $self;
}

sub _vari_pages { shift->{vari_pages} }
sub _default_epp { shift->{ENTRIES_PER_PAGE} }

sub entries_per_page {
        my $self = shift;
        return $self->_vari_pages->{$self->current_page} || $self->_default_epp;
}

sub first {
	my $self = shift;
	my $sum = 0;
	unless ($self->current_page == 1) {
		my $last = $self->current_page > $self->last_page ? $self->last_page : $self->current_page;
		for (1 .. $last - 1) {
			$sum += $self->_vari_pages->{$_} || $self->_default_epp;
		}
	}
	return $sum + 1;
}

sub last { 
	my $self = shift;
	my $sum = 0;
	if ($self->current_page == $self->last_page) {
		return $self->total_entries;
	} else { 
		for (1 .. $self->current_page) {
			$sum += $self->_vari_pages->{$_} || $self->_default_epp;
		}
		return $sum;
	}
}

sub last_page {
	my $self = shift;
	my ($count, $page) = (0, 0);
	while ($count < $self->total_entries) {
		$page++;
		$count += $self->_vari_pages->{$page} || $self->_default_epp;
	}
	return $page;
}

=head1 SHOWING YOU APPRECIATION

There was a thread on london.pm mailing list about working in a vacumn - that 
it was a bit depressing to keep writing modules but never get any feedback. So,
if you use and like this module then please send me an email and make my day.

All it takes is a few little bytes.

(Leon wrote that, not me!)

=head1 AUTHOR

Stray Toaster, E<lt>coder@stray-toaster.co.ukE<gt>

=head2 With Thanks

Leo for Data::Pageset. It rocks. 
(And also for a code suggestion, and taking the time to even look at this!)

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Stray Toaster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

return qw/I coded this to Queen Adreena and Black Rebel Motorcycle Club. Bizarre/;
