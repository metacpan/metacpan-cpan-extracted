package Dancer::Plugin::LDAP::Handle;

use strict;
use Carp;
use Net::LDAP;
use Net::LDAP::Util qw(escape_dn_value escape_filter_value ldap_explode_dn);
use Encode;

use base qw(Net::LDAP);

our $VERSION = '0.0050';

=head1 NAME

Dancer::Plugin::LDAP::Handle - subclassed Net::LDAP object

=head1 SYNOPSIS

=cut

=head1 METHODS

=cut

=head2 quick_select

quick_select performs a search in the LDAP directory.

The simplest form is to just specify the filter:

    ldap->quick_select({objectClass => 'inetOrgPerson'});

This retrieves all records of the object class C<inetOrgPerson>.

A specific record can be fetched by using the distinguished name (DN)
as only key in the hash reference:

    ldap->quick_select({dn => 'uid=racke@linuxia.de,dc=linuxia,dc=de'});

The base of your search can be passed as first argument, otherwise
the base defined in your settings will be used.

    ldap->quick_select('dc=linuxia,dc=de', {objectClass => 'inetOrgPerson'});

You may add any options supported by the Net::LDAP search method,
e.g.:

    ldap->quick_select('dc=linuxia,dc=de', {objectClass => 'inetOrgPerson'},
        scope => 'one');

=head3 Attributes

In addition, there is a C<values> option which determines how values
for LDAP attributes are fetched:

=over 4

=item first

First value of each attribute.

=item last

Last value of each attribute.

=item asref

Values as array reference.

=back

=cut

sub quick_select {
    my ($self) = shift;
    my ($table, $spec_ref, $mesg, @conds, $filter, $key,
	@search_args, @results, %opts, @ldap_args);

    if (ref($_[0]) eq 'HASH') {
	# search specification is first argument
	$table = $self->base();
    }
    else {
	$table = shift;
    }
	
    $spec_ref = shift;

    # check remaining parameters
    %opts = (values => 'first');

    while (@_ > 0) {
	$key = shift;
	
	if (exists $opts{$key}) {
	    $opts{$key} = shift;
	}
	else {
	    push(@ldap_args, $key, shift);
	}
    }

    @conds = $self->_build_conditions($spec_ref);

    if (@conds > 1) {
	$filter = '(&' . join('', @conds) . ')';
    }
    elsif (exists $spec_ref->{dn}) {
	# lookup of distinguished name
	$filter = '(objectClass=*)';
	$table = $spec_ref->{dn};
	push (@_, scope => 'base');
    }
    else {
	$filter = $conds[0];
    }

    # compose search parameters
    $table = $self->dn_escape($table);
    
    @search_args = (base => $table, filter => $filter, @_, @ldap_args);

    Dancer::Logger::debug('LDAP search: ', \@search_args);
	
    $mesg = $self->search(@search_args);

    foreach (my $i = 0; $i < $mesg->count; $i++) {
	my $token = {};
	my $entry = $mesg->entry($i);
	
	$token->{dn} = $self->_utf8_decode($self->dn_unescape($entry->dn));
	
	for my $attr ( $entry->attributes ) {
	    if ($opts{values} eq 'asref') {
		# all attribute values as array reference
		$token->{$attr} = [map {$self->_utf8_decode($_)} @{$entry->get_value($attr, asref => 1)}];
	    }
	    elsif ($opts{values} eq 'last') {
		# last attribute value
		my $value_ref =  $entry->get_value($attr, asref => 1);
		$token->{$attr} = defined($value_ref)
		    ? $self->_utf8_decode($value_ref->[-1])
		    : undef;
	    }
	    else {
		# first attribute value
		$token->{$attr} = $self->_utf8_decode($entry->get_value($attr));
	    }
	}
		
	push(@results, $token);
	
    }

    if (wantarray) {
	return @results;
    }
    else {
	return $results[0];
    }
}

=head2 quick_insert $dn $ref %opts

Adds an entry to LDAP directory.

    ldap->quick_insert('uid=racke@linuxia.de,ou=people,dc=linuxia,dc=de',
        {cn => 'racke@linuxia.de',
         uid => 'racke@linuxia.de',
         givenName = 'Stefan',
         sn => 'Hornburg',
         c => 'Germany',
         l => 'Wedemark',
         objectClass => [qw/top person organizationalPerson inetOrgPerson/],
        }

The fields which hold empty strings or undefined values will not be inserted,
but just ignored.

=cut

sub quick_insert {
    my ($self, $dn, $origref, %opts) = @_;
    my ($mesg);

    # escape DN
    $dn = $self->dn_escape($dn);

    # shallow copy of the ref
    my $ref = {};
    # sanitize the hash, LDAP *hates* empty strings
    while (my ($k, $value) =  each %$origref) {
        # ignore undefined values
        next unless defined $value;
        # ignore empty strings
        next if ((ref($value) eq '') and ($value eq ''));
        $ref->{$k} = $value;
    }

    Dancer::Logger::debug("LDAP insert, dn: ", $dn, "; data: ", $ref);
	
    $mesg = $self->add($dn, attr => [%$ref]);

    if ($mesg->code) {
	return $self->_failure('insert', $mesg, $opts{errors});
    }

    return $dn;
}

=head2 quick_compare $type $a $b $pos

=cut

sub quick_compare {
    my ($type, $a, $b, $pos) = @_;

    if ($type eq 'dn') {
	# explode both distinguished names
	my ($dn_a, $dn_b, $href_a, $href_b, $cmp);

	$dn_a = ldap_explode_dn($dn_a);
	$dn_b = ldap_explode_dn($dn_b);

	if (@$dn_a > @$dn_b) {
	    return 1;
	}
	elsif (@$dn_a < @$dn_b) {
	    return -1;
	}

	# check entries, starting from $pos
	$pos ||= 0;

	for (my $i = $pos; $i < @$dn_a; $i++) {
	    $href_a = $dn_a->[$i];
	    $href_b = $dn_b->[$i];

	    for my $k (keys %$href_a) {
		unless (exists($href_b->{$k})) {
		    return 1;
		}
		
		if ($cmp = $href_a->{$k} cmp $href_b->{$k}) {
		    return $cmp;
		}

		delete $href_b->{$k};
	    }

	    if (keys %$href_b) {
		return -1;
	    }
	}

	return 0;
    }
}

=head2 quick_update

Modifies LDAP entry with distinguished name $dn by replacing the
values from $replace. If the value is the empty string, delete the
attribute.

Returns DN in case of success.

    ldap->quick_update('uid=racke@linuxia.de,dc=linuxia,dc=de', {l => 'Vienna'});

=cut

sub quick_update {
    my ($self, $dn, $spec_ref) = @_;
    my ($mesg);

    # escape DN
    $dn = $self->dn_escape($dn);

    # do a shallow copy of the hashref
    my $spec_copy = { %$spec_ref };
    if ($spec_copy and (ref($spec_copy) eq 'HASH')) {
 
        # check if there are empty values passed
        while (my ($k, $v) = each %$spec_copy) {
            if ((ref($v) eq '') and ($v eq '')) {
                # in case replace them with an empty array ref to delete them
                $spec_copy->{$k} = [];
                Dancer::Logger::debug("$k is empty, replaced with []");
            }
        }
    }

    Dancer::Logger::debug("LDAP update, dn: ", $dn, "; data: ", $spec_copy);

    $mesg = $self->modify(dn => $dn, replace => $spec_copy);

    if ($mesg->code) {
	die "LDAP update failed (" . $mesg->code . ") with " . $mesg->error;
    }
    
    return $dn;
}

=head2 quick_delete

Deletes entry given by distinguished name $dn.

    ldap->quick_delete('uid=racke@linuxia.de,dc=linuxia,dc=de');

=cut

sub quick_delete {
    my ($self, $dn) = @_;
    my ($ldret);

    # escape DN
    $dn = $self->dn_escape($dn);

    Dancer::Logger::debug("LDAP delete: ", $dn);
    
    $ldret = $self->delete(dn => $dn);
    
    if ($ldret->code) {
	die "LDAP delete failed (" . $ldret->code . ") with " . $ldret->error;
    }

    return 1;
}

=head2 rename

Change distinguished name (DN) of a LDAP record from $old_dn to $new_dn.

=cut

sub rename {
    my ($self, $old_dn, $new_dn) = @_;
    my ($ldret, $old_ref, $new_ref, $rdn, $new_rdn, $superior, $ret,
	$old_escaped);

    $old_ref = $self->dn_split($old_dn, hash => 1);
    $new_ref = $self->dn_split($new_dn, hash => 1);

    if (@$new_ref == 1) {
	# got already relative DN
	$new_rdn = $new_dn;
    }
    else {
	# relative DN is first
	$rdn = shift @$new_ref;

	# check if it needs to move in the tree
#	if ($self->compare($old_dn, $new_dn, 1)) {
#	    die "Different LDAP trees.";
#	}

	$new_rdn = join('+', map {$_=$rdn->{$_}} keys %$rdn);
    }

    $old_escaped = join(',', @$old_ref);

    Dancer::Logger::debug("LDAP rename from $old_escaped to $new_rdn.");

    # change distinguished name
    $ldret = $self->moddn ($old_escaped, newrdn => $new_rdn);

    if ($ldret->code) {
	return $self->_failure('rename', $ldret);
    }

    # change attribute
 #   return $self->quick_update('');

    shift @$old_ref;
    return $self->dn_unescape(join(',', $new_rdn, @$old_ref));
}

=head2 base

Returns base DN, optionally prepending relative DN from @rdn.

    ldap->base

    ldap->base('uid=racke@linuxia.de');

=cut

sub base {
    my $self = shift;

    if (@_) {
	# prepend path
	return join(',', @_, $self->{dancer_settings}->{base});
    }

    return $self->{dancer_settings}->{base};
}

=head2 rebind

Rebind with credentials from settings.

=cut

sub rebind {
    my ($self) = @_;
    my ($ldret);

    Dancer::Logger::debug("LDAP rebind to $self->{dancer_settings}->{bind}.");
	
    $ldret = $self->bind($self->{dancer_settings}->{bind},
			 password => $self->{dancer_settings}->{password});

    if ($ldret->code) {
	Dancer::Logger::error('LDAP bind failed (' . $ldret->code . '): '
							  . $ldret->error);
	return;
    }

    return $self;
}

=head2 dn_split $dn %options

=cut

sub dn_split {
    my ($self, $dn, %options) = @_;
    my (@frags, @dn_parts, @out, @tmp, $buf, $value);

    # break DN up with regular expresssions
    @frags = reverse(split(/,/, $dn));

    $buf = '';

    for my $f (@frags) {
	@tmp = split(/=/, $f);

        if ($buf) {
	    $value = "$tmp[1],$buf";
        }
        elsif (@tmp > 1) {
            $value = $tmp[1];
        }
        else {
            $value = $tmp[0];
        }

        if (@tmp > 1) {
            if ($options{raw}) {
	    unshift @dn_parts, "$tmp[0]=" . $value;
            }
            else {
	    unshift @dn_parts, "$tmp[0]=" . escape_dn_value($value);
            }
            $buf = '';
        }
        else {
            $buf = $value;
        }
    }

    if ($options{hash}) {
	return \@dn_parts;
    }

    return join(',', @dn_parts);
}

=head2 dn_join $rdn1 $rdn2 ...

=cut

sub dn_join {
    my ($self, @rdn_list) = @_;
    my (@out);

    for my $rdn (@rdn_list) {
	if (ref($rdn) eq 'HASH') {
	    push (@out, join '+', 
		  map {"$_=" . $rdn->{$_}} keys %$rdn);
	}
	else {
	    push (@out, $rdn);
	}
    }

    return join(',', @out);
}

=head2 dn_escape

Escapes values in DN $dn and returns the altered string.

=cut

sub dn_escape {
    my ($self, $dn) = @_;

    return $self->dn_split($dn);    
}

=head2 dn_unescape

Unescapes values in DN $dn and returns the altered string.

=cut

sub dn_unescape {
    my ($self, $dn) = @_;
    my ($dn_ref);

    $dn_ref = ldap_explode_dn($dn);

    return $self->dn_join(@$dn_ref);
}

=head2 dn_value $dn $pos $attribute

Returns DN attribute value from $dn at position $pos,
matching attribute name $attribute.

$pos and $attribute are optional.

Returns undef in the following cases:

* invalid DN
* $pos exceeds number of entries in the DN
* attribute name doesn't match $attribute

Examples:

    ldap->dn_value('ou=Testing,dc=linuxia,dc=de');

    Testing

    ldap->dn_value('ou=Testing,dc=linuxia,dc=de', 1);

    linuxia

=cut

sub dn_value {
    my ($self, $dn, $pos, $attribute) = @_;
    my ($new_ref, $entry);

    $new_ref = ldap_explode_dn($dn);
    $pos ||= 0;

    unless (defined $new_ref) {
	return;
    }

    if ($pos >= @$new_ref) {
	return;
    }

    $entry = $new_ref->[$pos];

    if (defined $attribute) {
	# keys are by default uppercase
	$attribute = uc($attribute);

	if (exists $entry->{$attribute}) {
	    return $entry->{$attribute};
	}

	return;
    }

    return $entry->{values(%$entry)->[0]};
}

sub _failure {
	my ($self, $op, $mesg, $options) = @_;

	if ($options) {
		if (ref($options) eq 'HASH') {
			if ($mesg->code == 68) {
				# "Already exists"
				if ($options->{exists}) {
					return;
				}
			}
		}
	}

	my $errmsg = "LDAP $op failed (" . $mesg->code . ") with " . $mesg->error;

	if ($mesg->dn) {
		$errmsg .= ' (DN: ' . $mesg->dn . ')';
        }

	die $errmsg;
}

# build conditions for LDAP searches

sub _build_conditions {
    my ($self, $spec_ref) = @_;
    my ($key, $value, $safe_value, @conds, @sub_conds);

    while (($key, $value) = each(%$spec_ref)) {
	if ($key eq '-or') {
	    push @conds, '(|' . join('', $self->_build_conditions($value)) . ')';
	} elsif (ref($value) eq 'ARRAY') {
	    # Operator requested
	    if ($value->[0] eq 'exists') {
		if ($value->[1]) {
		    # attribute present
		    push (@conds, "($key=*)");
		}
		else {
		    # attribute missing
		    push (@conds, "(!($key=*))");
		}
	    }
	    elsif ($value->[0] eq '!' || $value->[0] eq 'not') {
		push (@conds, "(!($key=$value->[1]))");
	    }
	    elsif ($value->[0] eq 'substr'
		   || $value->[0] eq 'substring') {
		push (@conds, "($key=*" . escape_filter_value($value->[1]) . "*)");
	    }
        elsif ($value->[0] eq '<'
               || $value->[0] eq '<='
               || $value->[0] eq '>'
               || $value->[0] eq '>=') {
            push (@conds, "($key$value->[0]" . escape_filter_value($value->[1]) . ')');
        }
	    else {
		Dancer::Logger::debug("Invalid operator for $key: ", $value);
					die "Invalid operator $value->[0].";
	    }
	}
	else {
	    # escape filter value first
	    $safe_value = escape_filter_value($value);
	    push (@conds, "($key=$safe_value)");
	}
    }

    return @conds;
}

# fix UTF-8 encoding
sub _utf8_decode {
    my ($self, $string) = @_;

    unless(Encode::is_utf8($string)){
	$string = Encode::decode('utf-8', $string);
    }

    return $string;
}

=head1 DN

Our methods return and expect unescaped DN's.

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 ACKNOWLEDGEMENTS

See L<Dancer::Plugin::LDAP/ACKNOWLEDGEMENTS>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Dancer::Plugin::LDAP>

L<Dancer>

L<Net::LDAP>

=cut

1;

