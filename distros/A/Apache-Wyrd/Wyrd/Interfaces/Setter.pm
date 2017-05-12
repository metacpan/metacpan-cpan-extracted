use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Interfaces::Setter;
our $VERSION = '0.98';
use Apache::Util;

=pod

=head1 NAME

Apache::Wyrd::Interfaces::Setter - Templating Interface for Wyrds

=head1 SYNOPSIS

    !:information {<tr><td colspan="2">No information</td></tr>}
    ?:information {
      ?:phone{<tr><th>Phone:</th><td>$:phone</td></tr>}
      ?:fax{<tr><th>Fax:</th><td>$:fax</td></tr>}
      ?:email{<tr><th>Email:</th>
        <td><a href="mailto:$:email">$:email</a></td></tr>}
      ?:www{<tr><th>WWW:</th>
        <td><a href="$:www" target="external">$:www</a></td></tr>}
    }

    #interpret enclosed text and set enclosed text to result.
    $wyrd->_data($wyrd->_set());

    #interpret enclosed text and set the item placemarker.
    $wyrd->_data($wyrd->_set({item => 'this is the item'}));

    #interpret given template and set enclosed text to the result.
    $wyrd->_data($wyrd->_set(
      {item => 'this is the item'},
      'This is the item: $:item'
    ));

=head1 DESCRIPTION

The Setter interface give Wyrds a small templating "language" for
placing variables into HTML:  In short summary, there are two kinds of
tokens interpreted by the Setter: a placemarker and a conditional.  For
placemarkers, any valid perl variable name preceded by dollar-colon
("$:") is replaced by the value of that variable.  For conditionals, any
valid perl variable name preceded by an exclamation or question mark
and followed by curly braces enclosing text shows the enclosed text
conditionally if the variable is true ("?:") or false ("!:").  These
conditionals can be nested.

The Setter interface provides several "flavors" of Set-ting functions
depending on their purpose.  In general, however, they all accept two
optional variables, one being the hashref of variables to set with, the
second being the text which will be interpreted.  If the second variable
is not provided, it is assumed that the enclosed text is the text to be
processed.  If neither the first or the second is provided, it is also
assumed the CGI environment is the source for the variable substitution.

If the CGI environment is used, the Setter will use the minimum
necessary, only using the items it can clearly find in placemarkers.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<_set> ([hashref], [scalar])

Simplest flavor.  If a place-marked variable doesn't exist as a key in the
hashref which is the first argument (or in the CGI environment if the hashref is
not provided), then the placemarker is not interpreted, and remains untouched.

=cut

sub _set {
	my ($self, $hash, $temp) = @_;
	($hash, $temp) = $self->_setter_defaults($hash, $temp);
	$temp = $self->_regexp_conditionals($hash, $temp);
	$temp = $self->_setter_replacements($hash, $temp);
	return $temp;
}

=pod

=item (scalar) C<_clear_set> ([hashref], [scalar])

Same as _set, but wipes anything remaining that looks like a placemarker.

=cut

sub _clear_set {#clear out any unset values.
	my ($self, $hash, $temp) = @_;
	($hash, $temp) = $self->_setter_defaults($hash, $temp);
	$temp = $self->_clear_regexp_conditionals($hash, $temp);
	$temp = $self->_setter_replacements($hash, $temp);
	$temp =~ s/\$:[a-zA-Z_0-9]+//g;
	return $temp;
}

=pod

=item (scalar) C<_clean_set> ([hashref], [scalar])

More perl-ish.  If the placemarker is undefined OR false, it is not
interpreted.

=cut

sub _clean_set {
	#For making "set" more perl-ish and handling conditionals as if ''/null/undef value == undefined
	my ($self, $hash, $temp) = @_;
	($hash, $temp) = $self->_setter_defaults($hash, $temp);
	my %newhash = %$hash;
	foreach my $key (keys(%newhash)) {
		delete $newhash{$key} unless ($newhash{$key});#undefine missing bits for setter
	}
	$temp = $self->_regexp_conditionals($hash, $temp);
	return $self->_setter_replacements(\%newhash, $temp);
}

=pod

=item (scalar) C<_text_set> ([hashref], [scalar])

More text-ish and perl-ish.  If the placemarker is undefined OR false,
it is not interpreted.  Anything else that looks like a placemarker
after interpretation is finished is wiped out.  Generally safe for output
directly to web pages.

=cut

sub _text_set {
	#Like "_clean_set", but also interprets arrays and uses the _clear_set.
	#used for outputting directly to web pages
	my ($self, $hash, $temp) = @_;
	($hash, $temp) = $self->_setter_defaults($hash, $temp);
	$temp = $self->_regexp_conditionals($hash, $temp);
	my %newhash = %$hash;
	foreach my $key (keys(%newhash)) {
		$newhash{$key} = join ', ' , @{$newhash{$key}} if (ref($newhash{$key}) eq 'ARRAY');
		$newhash{$key} = '' unless ($newhash{$key} or ($newhash{$key} eq '0'));
	}
	return $self->_clear_set($hash, $temp);
}

=pod

=item (scalar) C<_quote_set> ([hashref], [scalar])

More SQL-ish, but not CGI-ish.  A blank hashref is used in place of the
CGI environment when passed no parameters.  Placemarkers are replaced
with the quote function of DBI via the Wyrd->dbl->quote function so as
to be used in SQL queries.

=cut

sub _quote_set {
	my ($self, $hash, $temp) = @_;
	#if a target ($temp) is provided, use it instead of the data
	$temp = $self->{'_data'} unless ($temp);
	$hash = {} unless (ref($hash) eq 'HASH');
	#first do conditionals
	$temp = $self->_regexp_conditionals($hash, $temp);
	#then do quotations, altering a copy, not the original
	my %hash = %$hash;
	foreach my $i (keys(%hash)) {
		$hash{$i}=$self->dbl->dbh->quote($hash{$i});
		$hash{$i}='NULL' if ($hash{$i} eq q(''));
	}
	#then do replacements
	foreach my $i (sort {length($b) <=> length($a)} keys(%hash)) {
		next unless ($i);#this is to prevent strange tied hashes from creating iloops
		$self->_verbose("temp is $temp, i is $i and hash is $$hash{$i}");
		$temp =~ s/\$:$i/$hash{$i}/gi;
	}
	return $temp;
}

=item (scalar) C<_cgi_quote_set> ([scalar])

same as C<_quote_set>, but with the CGI environment option forced and no
interpreted hash option.

=cut

sub _cgi_quote_set {
	my ($self, $temp) = @_;
	#if a target ($temp) is provided, use it instead of the data
	$temp = $self->{'_data'} unless ($temp);
	#first get a clean hash -- no point in doing conditionals if undef is changed to NULL
	my $hash = $self->_cgi_hash($temp);
	#then do conditionals
	$temp = $self->_regexp_conditionals($hash, $temp);
	#then do quotations
	$hash = $self->_cgi_hash($temp, 'quoted');
	#then do replacements
	foreach my $i (sort {length($b) <=> length($a)} keys(%$hash)) {
		next unless ($i);#this is to prevent strange tied hashes from creating iloops
		$self->_verbose("temp is $temp, i is $i and hash is $$hash{$i}");
		$temp =~ s/\$:$i/$$hash{$i}/gi;
	}
	return $temp;
}

=pod

=item (scalar) C<_escape_set> ([hashref], [scalar])

More HTML-form-ish but not CGI-ish.  A blank hashref is used in place of
the CGI environment when passed no parameters.  Values are HTML escaped
so they can be used within <input type="text"> tags in HTML.

=cut

sub _escape_set {
	my ($self, $hash, $temp) = @_;
	#if a target ($temp) is provided, use it instead of the data
	$temp = $self->{'_data'} unless ($temp);
	$hash = {} unless (ref($hash) eq 'HASH');
	#first do conditionals
	$temp = $self->_regexp_conditionals($hash, $temp);
	#then do quotations, altering a copy, not the original
	my %hash = %$hash;
	foreach my $i (keys(%hash)) {
		$hash{$i}=Apache::Util::escape_html($hash{$i});
	}
	#then do replacements
	foreach my $i (sort {length($b) <=> length($a)} keys(%hash)) {
		next unless ($i);#this is to prevent strange tied hashes from creating iloops
		$self->_verbose("temp is $temp, i is $i and hash is $$hash{$i}");
		$temp =~ s/\$:$i/$hash{$i}/gi;
	}
	return $temp;
}

=pod

=item (scalar) C<_cgi_escape_set>  ([scalar])

same as C<_escape_set>, but with the CGI environment option forced and
no interpreted hash option.

=cut

sub _cgi_escape_set {
	my ($self, $temp) = @_;
	#if a target ($temp) is provided, use it instead of the data
	$temp = $self->{'_data'} unless ($temp);
	#first get a clean hash -- no point in doing conditionals if undef is changed to NULL
	my $hash = $self->_cgi_hash($temp);
	#then do conditionals
	$temp = $self->_regexp_conditionals($hash, $temp);
	#then do quotations
	$hash = $self->_cgi_hash($temp, 'escaped');
	#then do replacements
	$temp = $self->_setter_replacements($hash, $temp);
	return $temp;
}

=pod

=item (scalar) C<_regexp_conditionals> (hashref, scalar)

internal method for performing conditional interpretation.

=cut

sub _regexp_conditionals {
	my ($self, $hash, $string) = @_;
	my $changed = 0; #toggle: if there is nothing left to change, it's time to return
	my $mode = 's'; #(s)eek a conditional (c)onfirm that it is a conditional, com(p)lete the expression
	my $state = '?'; #keep the argument or discard it
	my $buf = ''; #buffer for temp storage of the conditional
	my $out = ''; #buffer for the completed expression
	my $depth = 0; #how many layers of conditionals are we at?
	do {
		$changed = 0;
		foreach my $char (unpack('U*', $string)) {
			$char = chr($char);#returns unicode
			if ($mode eq 's') {#always begin by seeking
				if ($char eq '?' or $char eq '!') {
					$buf = '';
					$buf .= $char;
					$mode = 'c';
					$state = $char;
				} else {
					$out .= $char;
				}
			}
			elsif ($mode eq 'c') {
				if ((length($buf) > 3) and ($buf !~ /^[?!]:[_a-zA-Z][_a-zA-Z0-9]+$/)) {
					#not a valid identifier, move on...
					$out .= $buf . $char;
					$mode = 's';
				}
				if ($char eq '{') {
					my $identifier = substr($buf, 2);
					if (exists($$hash{$identifier})) {
						if (not(defined($$hash{$identifier}))) {
							$state =~ tr/?!/!?/;
						}
						$buf = '';
						$mode = 'p';
						$depth = 1;
						$changed = 1;
					} else {
						$out .= $buf . $char;
						$mode = 's';
					}
				} else {
					$buf .= $char;
				}
			}
			elsif ($mode eq 'p') {
				if($char eq '}') {
					$depth--
				}
				if($char eq '{') {
					$depth++
				}
				if ($depth == 0) {
					if ($state eq '?') {
						$out .= $self->_regexp_conditionals($hash, $buf);
					}
					$mode = 's';
				} else {
					$buf .= $char;
				}
			}
		}
		if ($mode eq 'p') {
			$self->_error('Malformed conditional in Setter:_[xxx_]set(). Aborting conditional expression evaluation.');
			return $string;
		}
		$string = $out;
		$out = '';
	} while ($changed);
	return $string;
}

=pod

=item (scalar) C<_clear_regexp_conditionals> (hashref, scalar)

internal method for performing conditional interpretation.  Unlike
_interpret_conditionals, this method considers the non-existence of a condition
to mean a negative value for the condition.

=cut

sub _clear_regexp_conditionals {
	my ($self, $hash, $string) = @_;
	my $result = undef;
	do {
		$result =
			$string =~ s/(\?:([a-zA-Z_][a-zA-Z_0-9]*)\{(?!.*\{)([^\}]*)\})/defined($$hash{$2})?$3:undef/ges;
		$result ||=
			$string =~ s/(\!:([a-zA-Z_][a-zA-Z_0-9]*)\{(?!.*\{)([^\}]*)\})/defined($$hash{$2})?undef:$3/ges;
	} while ($result);
	return $string;
}

=pod

=item (scalar) C<_setter_replacements> (hashref, scalar)

internal method for performing value replacements.

=cut

sub _setter_replacements {
	my ($self, $hash, $temp) = @_;
	foreach my $i (sort {length($b) <=> length($a)} keys(%$hash)) {
		#sorted so that the longest go first, avoiding problems where one variable (key) name is a
		#substring of another
		next unless ($i);#this is to prevent strange tied hashes from creating iloops
		$self->_verbose("temp is '$temp', i is '$i' and value is '$$hash{$i}'");
		$temp =~ s/\$:\Q$i\E/$$hash{$i}/gi;
	}
	return $temp;
}

=pod

=item (scalar) C<_setter_defaults> (hashref, scalar)

internal method for setting default template to BASECLASS::_data and default
parameters to null hash.

=cut

sub _setter_defaults {
	my ($self, $hash, $temp) = @_;
	#if a target ($temp) is provided, use it instead of the data
	$temp ||= $self->{'_data'};
	$hash = $self->_cgi_hash($temp) unless (ref($hash) eq 'HASH');
	return $hash, $temp;
}

=pod

=item (scalar) C<_cgi_hash> (hashref, scalar)

internal method for interpreting the CGI environment into the template
data hashref.

=cut

sub _cgi_hash {
	my ($self, $temp, $modifier) = @_;
	my $hash = {};
	my @params = ();
	unless ($temp) {
		#give up and use CGIs params
		@params = $self->dbl->param;
	} else {
		#guess at the params from the template
		@params = ($temp =~ m/[\$\?\!]\:([a-zA-Z_][a-zA-Z0-9_]+)/g);
	}
	foreach my $param (@params) {
		if ($modifier eq 'escaped') {
			$hash->{$param} = Apache::Util::escape_html(scalar($self->dbl->param($param)));
		} elsif ($modifier eq 'quoted') {
			#scalar is used because of some funny business in dbh -- worth investigating?
			$hash->{$param} = $self->dbl->dbh->quote(scalar($self->dbl->param($param)));
		} else {
			$hash->{$param} = $self->dbl->param($param);
		}
		$self->_verbose("$param = $$hash{$param}");
	}
	$self->_debug("Found params ->" . join ', ', @params);
	return $hash
}

=pod

=item (scalar) C<_attribute_template> (array)

Shortcut method for quickly creating templates of all attributes in a
wyrd, given an array of attribute names.

=cut

sub _attribute_template {
	my ($self, @attributes) = @_;
	my $string = join ('', map {qq(\?\:$_\{ $_="\$\:$_\"})} @attributes);
	return $string;
}

=pod

=item (scalar) C<_template_hash> (string, [hashref])

Shortcut method for quickly creating a hash from a template.  If the
template is not provided, the object's _data attribute is used.  If a
hashref is supplied as the second value, values for the returned hashref are
based on that. Otherwise, the calling object itself provides the values.  By
default, template items that are not defined by the attributes of the object
or provided hashref are ignored.

=cut

sub _template_hash {
	my ($self, $template, $hash) = @_;
	$template ||= $self->{'_data'};
	$hash ||= $self;
	my @keys = $template =~ /[\$\!\?]:([_a-zA-Z][_a-zA-Z0-9]+)/g;
	my %out_hash = ();
	foreach my $key (@keys) {
		if (eval{exists($hash->{$key})}) {
			$out_hash{$key} = $hash->{$key};
		}
	}
	return \%out_hash;
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

=head2 Interpolation Bug

"$:" is a variable in perl, so be sure to escape or single-quote your
in-code templates.  If you start seeing B<-variablename> in your pages,
you'll know why.

=head2 Defined Null Conditional Bug

There's some un-perlish behavior in the setting of conditionals.  Conditional
statements are set (?) or unset (!) depending on whether the item is defined,
not whether it is true.  An eq operator, for example, returns '' (the null
string) when the arguments are not equivalent strings, so a template with a
conditional that should be false, and therefore unset, is actually considered
true, since the result is defined and exists.  For example

    $result = $self->_set({'a' => 'a' eq 'b'}, '?:a{wrong}');

returns "wrong", not ''.  To prevent this, it should be written:

    $result = $self->_set({'a' => ('a' eq 'b') || undef}, '?:a{wrong}');

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;