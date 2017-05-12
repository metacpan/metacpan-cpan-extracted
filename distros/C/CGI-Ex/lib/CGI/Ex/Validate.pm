package CGI::Ex::Validate;

###---------------------###
#  See the perldoc in CGI/Ex/Validate.pod
#  Copyright 2003-2015 - Paul Seamons
#  Distributed under the Perl Artistic License without warranty

use strict;
use Carp qw(croak);

our $VERSION  = '2.44';
our $QR_EXTRA = qr/^(\w+_error|as_(array|string|hash)_\w+|no_\w+)/;
our @UNSUPPORTED_BROWSERS = (qr/MSIE\s+5.0\d/i);
our $JS_URI_PATH;
our $JS_URI_PATH_VALIDATE;

sub new {
    my $class = shift;
    return bless ref($_[0]) ? shift : {@_}, $class;
}

sub cgix { shift->{'cgix'} ||= do { require CGI::Ex; CGI::Ex->new } }

sub validate {
    my $self = (! ref($_[0])) ? shift->new            # $class->validate
        : UNIVERSAL::isa($_[0], __PACKAGE__) ? shift  # $self->validate
        : __PACKAGE__->new;                           # CGI::Ex::Validate::validate
    my ($form, $val_hash, $what_was_validated) = @_;

    die "Invalid form hash or cgi object" if ! $form || ! ref $form;
    $form = $self->cgix->get_form($form) if ref $form ne 'HASH';

    my ($fields, $ARGS) = $self->get_ordered_fields($val_hash);
    return if ! @$fields;

    return if $ARGS->{'validate_if'} && ! $self->check_conditional($form, $ARGS->{'validate_if'});

    # Finally we have our arrayref of hashrefs that each have their 'field' key
    # now lets do the validation
    $self->{'was_checked'} = {};
    $self->{'was_valid'}   = {};
    $self->{'had_error'}   = {};
    my $found  = 1;
    my @errors;
    my $hold_error; # hold the error for a moment - to allow for an "OR" operation
    my %checked;
    foreach (my $i = 0; $i < @$fields; $i++) {
        my $ref = $fields->[$i];
        if (! ref($ref) && $ref eq 'OR') {
            $i++ if $found; # if found skip the OR altogether
            $found = 1; # reset
            next;
        }
        $found = 1;
        my $key = $ref->{'field'} || die "Missing field key during normal validation";

        # allow for field names that contain regular expressions
        my @keys;
        if ($key =~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
            my ($not,$pat,$opt) = ($1,$3,$4);
            $opt =~ tr/g//d;
            die "The e option cannot be used on validation keys on field $key" if $opt =~ /e/;
            foreach my $_key (sort keys %$form) {
                next if ($not && $_key =~ m/(?$opt:$pat)/) || (! $not && $_key !~ m/(?$opt:$pat)/);
                push @keys, [$_key, [undef, $1, $2, $3, $4, $5]];
            }
        } else {
            @keys = ([$key]);
        }

        foreach my $r (@keys) {
            my ($field, $ifs_match) = @$r;
            if (! $checked{$field}++) {
                $self->{'was_checked'}->{$field} = 1;
                $self->{'was_valid'}->{$field} = 1;
                $self->{'had_error'}->{$field} = 0;
            }
            local $ref->{'was_validated'} = 1;
            my $err = $self->validate_buddy($form, $field, $ref, $ifs_match);
            if ($ref->{'was_validated'}) {
                push @$what_was_validated, $ref if $what_was_validated;
            } else {
                $self->{'was_valid'}->{$field} = 0;
            }

            # test the error - if errors occur allow for OR - if OR fails use errors from first fail
            if ($err) {
                $self->{'was_valid'}->{$field} = 0;
                $self->{'had_error'}->{$field} = 0;
                if ($i < $#$fields && ! ref($fields->[$i + 1]) && $fields->[$i + 1] eq 'OR') {
                    $hold_error = $err;
                } else {
                    push @errors, $hold_error ? @$hold_error : @$err;
                    $hold_error = undef;
                }
            } else {
                $hold_error = undef;
            }
        }
    }
    push(@errors, @$hold_error) if $hold_error; # allow for final OR to work

    # optionally check for unused keys in the form
    if ($ARGS->{no_extra_fields} || $self->{no_extra_fields}) {
        my %keys = map { ($_->{'field'} => 1) } @$fields;
        foreach my $key (sort keys %$form) {
            next if $keys{$key};
            push @errors, [$key, 'no_extra_fields', {}, undef];
        }
    }

    if (@errors) {
        my @copy = grep {/$QR_EXTRA/o} keys %$self;
        @{ $ARGS }{@copy} = @{ $self }{@copy};
        unshift @errors, $ARGS->{'title'} if $ARGS->{'title'};
        my $err_obj = $self->new_error(\@errors, $ARGS);
        die    $err_obj if $ARGS->{'raise_error'};
        return $err_obj;
    }

    return; # success
}

sub get_ordered_fields {
    my ($self, $val_hash) = @_;

    die "Missing validation hash" if ! $val_hash;
    if (ref $val_hash ne 'HASH') {
        $val_hash = $self->get_validation($val_hash) if ref $val_hash ne 'SCALAR' || ! ref $val_hash;
        die "Validation groups must be a hashref"    if ref $val_hash ne 'HASH';
    }

    my %ARGS;
    my @field_keys = grep { /^(?:group|general)\s+(\w+)/
                              ? do {$ARGS{$1} = $val_hash->{$_} ; 0}
                              : 1 } sort keys %$val_hash;

    # Look first for items in 'group fields' or 'group order'
    my $fields;
    if (my $ref = $ARGS{'fields'} || $ARGS{'order'}) {
        my $type = $ARGS{'fields'} ? 'group fields' : 'group order';
        die "Validation '$type' must be an arrayref when passed" if ! UNIVERSAL::isa($ref, 'ARRAY');
        foreach my $field (@$ref) {
            die "Non-defined value in '$type'" if ! defined $field;
            if (ref $field) {
                die "Found nonhashref value in '$type'" if ref($field) ne 'HASH';
                die "Element missing \"field\" key/value in '$type'" if ! defined $field->{'field'};
                push @$fields, $field;
            } elsif ($field eq 'OR') {
                push @$fields, 'OR';
            } else {
                die "No element found in '$type' for $field" if ! exists $val_hash->{$field};
                die "Found nonhashref value in '$type'" if ref($val_hash->{$field}) ne 'HASH';
                my $val = $val_hash->{$field};
                $val = {%$val, field => $field} if ! $val->{'field'};  # copy the values to add the key
                push @$fields, $val;
            }
        }

        # limit the keys that need to be searched to those not in fields or order
        my %found = map { ref($_) ? ($_->{'field'} => 1) : () } @$fields;
        @field_keys = grep { ! $found{$_} } @field_keys;
    }

    # add any remaining field_vals from our original hash
    # this is necessary for items that weren't in group fields or group order
    foreach my $field (@field_keys) {
        die "Found nonhashref value for field $field" if ref($val_hash->{$field}) ne 'HASH';
        if (defined $val_hash->{$field}->{'field'}) {
            push @$fields, $val_hash->{$field};
        } else {
            push @$fields, { %{$val_hash->{$field}}, field => $field };
        }
    }

    return ($fields || [], \%ARGS);
}

sub new_error {
    my $self = shift;
    return CGI::Ex::Validate::Error->new(@_);
}

### allow for optional validation on groups and on individual items
sub check_conditional {
    my ($self, $form, $ifs, $ifs_match) = @_;
    die "Need reference passed to check_conditional" if ! $ifs;
    $ifs = [$ifs] if ! ref($ifs) || UNIVERSAL::isa($ifs,'HASH');

    local $self->{'_check_conditional'} = 1;

    # run the if options here
    # multiple items can be passed - all are required unless OR is used to separate
    my $found = 1;
    foreach (my $i = 0; $i <= $#$ifs; $i ++) {
        my $ref = $ifs->[$i];
        if (! ref $ref) {
            if ($ref eq 'OR') {
                $i++ if $found; # if found skip the OR altogether
                $found = 1; # reset
                next;
            } else {
                if ($ref =~ /^function\s*\(/) {
                    next;
                } elsif ($ref =~ /^(.*?)\s+(was_valid|had_error|was_checked)$/) {
                    $ref = {field => $1, $2 => 1};
                } elsif ($ref =~ s/^\s*!\s*//) {
                    $ref = {field => $ref, max_in_set => "0 of $ref"};
                } else {
                    $ref = {field => $ref, required => 1};
                }
            }
        }
        last if ! $found;

        # get the field - allow for custom variables based upon a match
        my $field = $ref->{'field'} || die "Missing field key during validate_if (possibly used a reference to a main hash *foo -> &foo)";
        $field =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;

        my $errs = $self->validate_buddy($form, $field, $ref);

        $found = 0 if $errs;
    }
    return $found;
}


### this is where the main checking goes on
sub validate_buddy {
    my ($self, $form, $field, $field_val, $ifs_match) = @_;
    local $self->{'_recurse'} = ($self->{'_recurse'} || 0) + 1;
    die "Max dependency level reached 10" if $self->{'_recurse'} > 10;
    my @errors;

    if ($field_val->{'exclude_cgi'}) {
        delete $field_val->{'was_validated'};
        return 0;
    }

    # allow for field names that contain regular expressions
    if ($field =~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
        my ($not,$pat,$opt) = ($1,$3,$4);
        $opt =~ tr/g//d;
        die "The e option cannot be used on validation keys on field $field" if $opt =~ /e/;
        foreach my $_field (sort keys %$form) {
            next if ($not && $_field =~ m/(?$opt:$pat)/) || (! $not && $_field !~ m/(?$opt:$pat)/);
            my $errs = $self->validate_buddy($form, $_field, $field_val, [undef, $1, $2, $3, $4, $5]);
            push @errors, @$errs if $errs;
        }
        return @errors ? \@errors : 0;
    }

    if ($field_val->{'was_valid'}   && ! $self->{'was_valid'}->{$field})   { return [[$field, 'was_valid',   $field_val, $ifs_match]]; }
    if ($field_val->{'had_error'}   && ! $self->{'had_error'}->{$field})   { return [[$field, 'had_error',   $field_val, $ifs_match]]; }
    if ($field_val->{'was_checked'} && ! $self->{'was_checked'}->{$field}) { return [[$field, 'was_checked', $field_val, $ifs_match]]; }


    # allow for default value
    if (defined($field_val->{'default'})
        && (!defined($form->{$field})
            || (UNIVERSAL::isa($form->{$field},'ARRAY') ? !@{ $form->{$field} } : !length($form->{$field})))) {
        $form->{$field} = $field_val->{'default'};
    }

    my $values   = UNIVERSAL::isa($form->{$field},'ARRAY') ? $form->{$field} : [$form->{$field}];
    my $n_values = @$values;

    # allow for a few form modifiers
    my $modified = 0;
    foreach my $value (@$values) {
        next if ! defined $value;
        if (! $field_val->{'do_not_trim'}) { # whitespace
            $modified = 1 if  $value =~ s/( ^\s+ | \s+$ )//xg;
        }
        if ($field_val->{'trim_control_chars'}) {
            $modified = 1 if $value =~ y/\t/ /;
            $modified = 1 if $value =~ y/\x00-\x1F//d;
        }
        if ($field_val->{'to_upper_case'}) { # uppercase
            $value = uc $value;
            $modified = 1;
        } elsif ($field_val->{'to_lower_case'}) { # lowercase
            $value = lc $value;
            $modified = 1;
        }
    }

    my %types;
    foreach (sort keys %$field_val) {
        push @{$types{$1}}, $_ if /^ (compare|custom|equals|match|max_in_set|min_in_set|replace|required_if|sql|type|validate_if) _?\d* $/x;
    }

    # allow for inline specified modifications (ie s/foo/bar/)
    if ($types{'replace'}) { foreach my $type (@{ $types{'replace'} }) {
        my $ref = UNIVERSAL::isa($field_val->{$type},'ARRAY') ? $field_val->{$type}
        : [split(/\s*\|\|\s*/,$field_val->{$type})];
        foreach my $rx (@$ref) {
            if ($rx !~ m/^\s*s([^\s\w])(.+)\1(.*)\1([eigsmx]*)$/s) {
                die "Not sure how to parse that replace ($rx)";
            }
            my ($pat, $swap, $opt) = ($2, $3, $4);
            die "The e option cannot be used in swap on field $field" if $opt =~ /e/;
            my $global = $opt =~ s/g//g;
            $swap =~ s/\\n/\n/g;
            my $expand = sub { # code similar to Template::Alloy::VMethod::vmethod_replace
                my ($text, $start, $end) = @_;
                my $copy = $swap;
                $copy =~ s{ \\(\\|\$) | \$ (\d+) }{
                    $1 ? $1
                        : ($2 > $#$start || $2 == 0) ? ''
                        : substr($text, $start->[$2], $end->[$2] - $start->[$2]);
                }exg;
                $modified = 1;
                $copy;
            };
            foreach my $value (@$values) {
                if ($global) { $value =~ s{(?$opt:$pat)}{ $expand->($value, [@-], [@+]) }eg }
                else         { $value =~ s{(?$opt:$pat)}{ $expand->($value, [@-], [@+]) }e  }
            }
        }
    } }
    $form->{$field} = $values->[0] if $modified && $n_values == 1; # put them back into the form if we have modified it

    # only continue if a validate_if is not present or passes test
    my $needs_val = 0;
    my $n_vif = 0;
    if ($types{'validate_if'}) { foreach my $type (@{ $types{'validate_if'} }) {
        $n_vif++;
        my $ifs = $field_val->{$type};
        my $ret = $self->check_conditional($form, $ifs, $ifs_match);
        $needs_val++ if $ret;
    } }
    if (! $needs_val && $n_vif) {
        delete $field_val->{'was_validated'};
        return 0;
    }

    # check for simple existence
    # optionally check only if another condition is met
    my $is_required = $field_val->{'required'} ? 'required' : '';
    if (! $is_required) {
        if ($types{'required_if'}) { foreach my $type (@{ $types{'required_if'} }) {
            my $ifs = $field_val->{$type};
            next if ! $self->check_conditional($form, $ifs, $ifs_match);
            $is_required = $type;
            last;
        } }
    }
    if ($is_required
        && ($n_values == 0 || ($n_values == 1 && (! defined($values->[0]) || ! length $values->[0])))) {
        return [] if $self->{'_check_conditional'};
        return [[$field, $is_required, $field_val, $ifs_match]];
    }

    my $n = exists($field_val->{'min_values'}) ? $field_val->{'min_values'} || 0 : 0;
    if ($n_values < $n) {
        return [] if $self->{'_check_conditional'};
        return [[$field, 'min_values', $field_val, $ifs_match]];
    }

    $field_val->{'max_values'} = 1 if ! exists $field_val->{'max_values'};
    $n = $field_val->{'max_values'} || 0;
    if ($n_values > $n) {
        return [] if $self->{'_check_conditional'};
        return [[$field, 'max_values', $field_val, $ifs_match]];
    }

    foreach ([min => $types{'min_in_set'}],
             [max => $types{'max_in_set'}]) {
        my $keys   = $_->[1] || next;
        my $minmax = $_->[0];
        foreach my $type (@$keys) {
            $field_val->{$type} =~ m/^\s*(\d+)(?i:\s*of)?\s+(.+)\s*$/
                || die "Invalid ${minmax}_in_set check $field_val->{$type}";
            my $n = $1;
            foreach my $_field (split /[\s,]+/, $2) {
                my $ref = UNIVERSAL::isa($form->{$_field},'ARRAY') ? $form->{$_field} : [$form->{$_field}];
                foreach my $_value (@$ref) {
                    $n -- if defined($_value) && length($_value);
                }
            }
            if (   ($minmax eq 'min' && $n > 0)
                   || ($minmax eq 'max' && $n < 0)) {
                return [] if $self->{'_check_conditional'};
                return [[$field, $type, $field_val, $ifs_match]];
            }
        }
    }

    # at this point @errors should still be empty
    my $content_checked; # allow later for possible untainting (only happens if content was checked)

    OUTER: foreach my $value (@$values) {

        if (exists $field_val->{'enum'}) {
            my $ref = ref($field_val->{'enum'}) ? $field_val->{'enum'} : [split(/\s*\|\|\s*/,$field_val->{'enum'})];
            my $found = 0;
            foreach (@$ref) {
                $found = 1 if defined($value) && $_ eq $value;
            }
            if (! $found) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, 'enum', $field_val, $ifs_match];
                next OUTER;
            }
            $content_checked = 1;
        }

        # do specific type checks
        if (exists $field_val->{'type'}) {
            if (! $self->check_type($value, $field_val->{'type'}, $field, $form)){
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, 'type', $field_val, $ifs_match];
                next OUTER;
            }
            $content_checked = 1;
        }

        # field equals another field
        if ($types{'equals'}) { foreach my $type (@{ $types{'equals'} }) {
            my $field2  = $field_val->{$type};
            my $not     = ($field2 =~ s/^!\s*//) ? 1 : 0;
            my $success = 0;
            if ($field2 =~ m/^([\"\'])(.*)\1$/) {
                my $test = $2;
                $success = (defined($value) && $value eq $test);
            } else {
                $field2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
                if (exists($form->{$field2}) && defined($form->{$field2})) {
                    $success = (defined($value) && $value eq $form->{$field2});
                } elsif (! defined($value)) {
                    $success = 1; # occurs if they are both undefined
                }
            }
            if ($not ? $success : ! $success) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, $type, $field_val, $ifs_match];
                next OUTER;
            }
            $content_checked = 1;
        } }

        if (exists $field_val->{'min_len'}) {
            my $n = $field_val->{'min_len'};
            if (! defined($value) || length($value) < $n) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, 'min_len', $field_val, $ifs_match];
            }
        }

        if (exists $field_val->{'max_len'}) {
            my $n = $field_val->{'max_len'};
            if (defined($value) && length($value) > $n) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, 'max_len', $field_val, $ifs_match];
            }
        }

        # now do match types
        if ($types{'match'}) { foreach my $type (@{ $types{'match'} }) {
            my $ref = UNIVERSAL::isa($field_val->{$type},'ARRAY') ? $field_val->{$type}
                : UNIVERSAL::isa($field_val->{$type}, 'Regexp')   ? [$field_val->{$type}]
                : [split(/\s*\|\|\s*/,$field_val->{$type})];
            foreach my $rx (@$ref) {
                if (UNIVERSAL::isa($rx,'Regexp')) {
                    if (! defined($value) || $value !~ $rx) {
                        push @errors, [$field, $type, $field_val, $ifs_match];
                    }
                } else {
                    if ($rx !~ m/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/s) {
                        die "Not sure how to parse that match ($rx)";
                    }
                    my ($not, $pat, $opt) = ($1, $3, $4);
                    $opt =~ tr/g//d;
                    die "The e option cannot be used on validation keys on field $field" if $opt =~ /e/;
                    if ( (     $not && (  defined($value) && $value =~ m/(?$opt:$pat)/))
                         || (! $not && (! defined($value) || $value !~ m/(?$opt:$pat)/)) ) {
                        return [] if $self->{'_check_conditional'};
                        push @errors, [$field, $type, $field_val, $ifs_match];
                    }
                }
            }
            $content_checked = 1;
        } }

        # allow for comparison checks
        if ($types{'compare'}) { foreach my $type (@{ $types{'compare'} }) {
            my $ref = UNIVERSAL::isa($field_val->{$type},'ARRAY') ? $field_val->{$type}
            : [split(/\s*\|\|\s*/,$field_val->{$type})];
            foreach my $comp (@$ref) {
                next if ! $comp;
                my $test  = 0;
                if ($comp =~ /^\s*(>|<|[><!=]=)\s*([\d\.\-]+)\s*$/) {
                    my $val = $value || 0;
                    $val *= 1;
                    if    ($1 eq '>' ) { $test = ($val >  $2) }
                    elsif ($1 eq '<' ) { $test = ($val <  $2) }
                    elsif ($1 eq '>=') { $test = ($val >= $2) }
                    elsif ($1 eq '<=') { $test = ($val <= $2) }
                    elsif ($1 eq '!=') { $test = ($val != $2) }
                    elsif ($1 eq '==') { $test = ($val == $2) }

                } elsif ($comp =~ /^\s*(eq|ne|gt|ge|lt|le)\s+(.+?)\s*$/) {
                    my $val = defined($value) ? $value : '';
                    my ($op, $value2) = ($1, $2);
                    $value2 =~ s/^([\"\'])(.*)\1$/$2/;
                    if    ($op eq 'gt') { $test = ($val gt $value2) }
                    elsif ($op eq 'lt') { $test = ($val lt $value2) }
                    elsif ($op eq 'ge') { $test = ($val ge $value2) }
                    elsif ($op eq 'le') { $test = ($val le $value2) }
                    elsif ($op eq 'ne') { $test = ($val ne $value2) }
                    elsif ($op eq 'eq') { $test = ($val eq $value2) }

                } else {
                    die "Not sure how to compare \"$comp\"";
                }
                if (! $test) {
                    return [] if $self->{'_check_conditional'};
                    push @errors, [$field, $type, $field_val, $ifs_match];
                }
            }
            $content_checked = 1;
        } }

        # server side sql type
        if ($types{'sql'}) { foreach my $type (@{ $types{'sql'} }) {
            my $db_type = $field_val->{"${type}_db_type"};
            my $dbh = ($db_type) ? $self->{dbhs}->{$db_type} : $self->{dbh};
            if (! $dbh) {
                die "Missing dbh for $type type on field $field" . ($db_type ? " and db_type $db_type" : "");
            } elsif (UNIVERSAL::isa($dbh,'CODE')) {
                $dbh = &$dbh($field, $self) || die "SQL Coderef did not return a dbh";
            }
            my $sql  = $field_val->{$type};
            my @args = ($value) x $sql =~ tr/?//;
            my $return = $dbh->selectrow_array($sql, {}, @args); # is this right - copied from O::FORMS
            $field_val->{"${type}_error_if"} = 1 if ! defined $field_val->{"${type}_error_if"};
            if ( (! $return && $field_val->{"${type}_error_if"})
                 || ($return && ! $field_val->{"${type}_error_if"}) ) {
                return [] if $self->{'_check_conditional'};
                push @errors, [$field, $type, $field_val, $ifs_match];
            }
            $content_checked = 1;
        } }

        # server side custom type
        if ($types{'custom'}) { foreach my $type (@{ $types{'custom'} }) {
            my $check = $field_val->{$type};
            my $err;
            if (UNIVERSAL::isa($check, 'CODE')) {
                my $ok;
                $err = "$@" if ! eval { $ok = $check->($field, $value, $field_val, $type, $form); 1 };
                next if $ok;
                chomp($err) if !ref($@) && defined($err);
            } else {
                next if $check;
            }
            return [] if $self->{'_check_conditional'};
            push @errors, [$field, $type, $field_val, $ifs_match, (defined($err) ? $err : ())];
            $content_checked = 1;
        } }

    }

    # allow for the data to be "untainted"
    # this is only allowable if the user ran some other check for the datatype
    if ($field_val->{'untaint'} && $#errors == -1) {
        if (! $content_checked) {
            push @errors, [$field, 'untaint', $field_val, $ifs_match];
        } else {
            # generic untainter - assuming the other required content_checks did good validation
            $_ = /(.*)/ ? $1 : die "Couldn't match?" foreach @$values;
            if ($n_values == 1) {
                $form->{$field} = $values->[0];
            }
        }
    }

    # all done - time to return
    return @errors ? \@errors : 0;
}

###---------------------###

### used to validate specific types
sub check_type {
    my ($self, $value, $type) = @_;
    $type = lc $type;
    if ($type eq 'email') {
        return 0 if ! $value;
        my ($local_p,$dom) = ($value =~ /^(.+)\@(.+?)$/) ? ($1,$2) : return 0;
        return 0 if length($local_p) > 60;
        return 0 if length($dom) > 100;
        return 0 if ! $self->check_type($dom,'domain') && ! $self->check_type($dom,'ip');
        return 0 if ! $self->check_type($local_p,'local_part');

    # the "username" portion of an email address - sort of arbitrary
    } elsif ($type eq 'local_part') {
        return 0 if ! defined($value) || ! length($value);
        # ignoring all valid quoted string local parts
        return 0 if $value =~ m/[^\w.~!\#\$%\^&*\-=+?]/;

    # standard IP address
    } elsif ($type eq 'ip') {
        return 0 if ! $value;
        return (4 == grep {!/\D/ && $_ < 256} split /\./, $value, 4);

    # domain name - including tld and subdomains (which are all domains)
    } elsif ($type eq 'domain') {
        return 0 if ! $value || length($value) > 255;
        return 0 if $value !~ /^([a-z0-9][a-z0-9\-]{0,62} \.)+ [a-z]{1,63}$/ix
            || $value =~ m/(\.\-|\-\.|\.\.)/;

    # validate a url
    } elsif ($type eq 'url') {
        return 0 if ! $value;
        $value =~ s|^https?://([^/]+)||i || return 0;
        my $dom = $1;
        return 0 if ! $self->check_type($dom,'domain') && ! $self->check_type($dom,'ip');
        return 0 if $value && ! $self->check_type($value,'uri');

    # validate a uri - the path portion of a request
    } elsif ($type eq 'uri') {
        return 0 if ! $value;
        return 0 if $value =~ m/\s+/;

    } elsif ($type eq 'int') {
        return 0 if $value !~ /^-? (?: 0 | [1-9]\d*) $/x;
        return 0 if ($value < 0) ? $value < -2**31 : $value > 2**31-1;
    } elsif ($type eq 'uint') {
        return 0 if $value !~ /^   (?: 0 | [1-9]\d*) $/x;
        return 0 if $value > 2**32-1;
    } elsif ($type eq 'num') {
        return 0 if $value !~ /^-? (?: 0 | [1-9]\d* (?:\.\d+)? | 0?\.\d+) $/x;

    } elsif ($type eq 'cc') {
        return 0 if ! $value;
        return 0 if $value =~ /[^\d\-\ ]/;
        $value =~ s/\D//g;
        return 0 if length($value) > 16 || length($value) < 13;

        # simple mod10 check
        my $sum    = 0;
        my $switch = 0;
        foreach my $digit (reverse split //, $value) {
            $switch = 1 if ++$switch > 2;
            my $y = $digit * $switch;
            $y -= 9 if $y > 9;
            $sum += $y;
        }
        return 0 if $sum % 10;

    }

    return 1;
}

###---------------------###

sub get_validation {
    my ($self, $val) = @_;
    require CGI::Ex::Conf;
    return CGI::Ex::Conf::conf_read($val, {html_key => 'validation', default_ext => 'val'});
}

### returns all keys from all groups - even if group has validate_if
sub get_validation_keys {
    my ($self, $val_hash, $form) = @_; # with optional form - will only return keys in validated groups

    if ($form) {
        die "Invalid form hash or cgi object" if ! ref $form;
        $form = $self->cgix->get_form($form) if ref $form ne 'HASH';
    }

    my ($fields, $ARGS) = $self->get_ordered_fields($val_hash);
    return {} if ! @$fields;
    return {} if $form && $ARGS->{'validate_if'} && ! $self->check_conditional($form, $ARGS->{'validate_if'});
    return {map { $_->{'field'} = $_->{'name'} || 1 } @$fields};
}

###---------------------###

sub generate_js {
    return "<!-- JS validation not supported in this browser $_ -->"
        if $ENV{'HTTP_USER_AGENT'} && grep {$ENV{'HTTP_USER_AGENT'} =~ $_} @UNSUPPORTED_BROWSERS;

    my $self = shift;
    my $val_hash = shift || croak "Missing validation hash";
    if (ref $val_hash ne 'HASH') {
        $val_hash = $self->get_validation($val_hash) if ref $val_hash ne 'SCALAR' || ! ref $val_hash;
        croak "Validation groups must be a hashref"    if ref $val_hash ne 'HASH';
    }

    my ($args, $form_name, $js_uri_path);
    croak "Missing args or form_name" if ! $_[0];
    if (ref($_[0]) eq 'HASH') {
        $args = shift;
    } else {
        ($args, $form_name, $js_uri_path) = ({}, @_);
    }

    $form_name   ||= $args->{'form_name'}   || croak 'Missing form_name';
    $js_uri_path ||= $args->{'js_uri_path'};

    my $js_uri_path_validate = $JS_URI_PATH_VALIDATE || do {
        croak 'Missing js_uri_path' if ! $js_uri_path;
        "$js_uri_path/CGI/Ex/validate.js";
    };

    require CGI::Ex::JSONDump;
    my $json = CGI::Ex::JSONDump->new({pretty => 1})->dump($val_hash);
    return qq{<script src="$js_uri_path_validate"></script>
<script>
document.validation = $json;
if (document.check_form) document.check_form("$form_name");
</script>
};
}

sub generate_form {
    my ($self, $val_hash, $form_name, $args) = @_;
    ($args, $form_name) = ($form_name, undef) if ref($form_name) eq 'HASH';

    my ($fields, $ARGS) = $self->get_ordered_fields($val_hash);
    $args = {%{ $ARGS->{'form_args'} || {}}, %{ $args || {} }};

    my $cols = ($args->{'no_inline_error'} || ! $args->{'columns'} || $args->{'columns'} != 3) ? 2 : 3;
    $args->{'div'}       ||= "<div class=\"form_div\">\n";
    $args->{'open'}      ||= "<form name=\"\$form_name\" id=\"\$form_name\" method=\"\$method\" action=\"\$action\"\$extra_form_attrs>\n";
    $args->{'form_name'} ||= $form_name || 'the_form_'.int(rand * 1000);
    $args->{'action'}    ||= '';
    $args->{'method'}    ||= 'POST';
    $args->{'submit'}    ||= "<input type=\"submit\" value=\"".($args->{'submit_name'} || 'Submit')."\">";
    $args->{'header'}    ||= "<table class=\"form_table\">\n";
    $args->{'header'}    .=  "  <tr class=\"header\"><th colspan=\"$cols\">\$title</th></tr>\n" if $args->{'title'};
    $args->{'footer'}    ||= "  <tr class=\"submit_row\"><th colspan=\"2\">\$submit</th></tr>\n</table>\n";
    $args->{'row_template'} ||= "  <tr class=\"\$oddeven\" id=\"\$field_row\">\n"
        ."    <td class=\"field\">\$name</td>\n"
        ."    <td class=\"input\">\$input"
        . ($cols == 2
             ? ($args->{'no_inline_error'} ? '' : "<br /><span class=\"error\" id=\"\$field_error\">[% \$field_error %]</span></td>\n")
             : "</td>\n    <td class=\"error\" id=\"\$field_error\">[% \$field_error %]</td>\n")
        ."  </tr>\n";

    my $js = ! defined($args->{'use_js_validation'}) || $args->{'use_js_validation'};

    $args->{'css'} = ".odd { background: #eee }\n"
        . ".form_div { width: 40em; }\n"
        . ".form_div td { padding:.5ex;}\n"
        . ".form_div label { width: 10em }\n"
        . ".form_div .error { color: darkred }\n"
        . "table { border-spacing: 0px }\n"
        . ".submit_row { text-align: right }\n"
        if ! defined $args->{'css'};

    my $txt = ($args->{'css'} ? "<style>\n$args->{'css'}\n</style>\n" : '') . $args->{'div'} . $args->{'open'} . $args->{'header'};
    s/\$(form_name|title|method|action|submit|extra_form_attrs)/$args->{$1}/g foreach $txt, $args->{'footer'};
    my $n = 0;
    foreach my $field (@$fields) {
        my $input;
        my $type = $field->{'htype'} ? $field->{'htype'} : $field->{'field'} =~ /^pass(?:|wd|word|\d+|_\w+)$/i ? 'password' : 'text';
        if ($type eq 'hidden') {
            $txt .= "$input\n";
            next;
        } elsif ($type eq 'textarea' || $field->{'rows'} || $field->{'cols'}) {
            my $r = $field->{'rows'} ? " rows=\"$field->{'rows'}\"" : '';
            my $c = $field->{'cols'} ? " cols=\"$field->{'cols'}\"" : '';
            my $w = $field->{'wrap'} ? " wrap=\"$field->{'wrap'}\"" : '';
            $input = "<textarea name=\"$field->{'field'}\" id=\"$field->{'field'}\"$r$c$w></textarea>";
        } elsif ($type eq 'radio' || $type eq 'checkbox') {
            my $e = $field->{'enum'}  || [];
            my $l = $field->{'label'} || $e;
            my $I = @$e > @$l ? $#$e : $#$l;
            for (my $i = 0; $i <= $I; $i++) {
                my $_e = $e->[$i];
                $_e =~ s/\"/&quot;/g;
                $input .= "<div class=\"option\"><input type=\"$type\" name=\"$field->{'field'}\" id=\"$field->{'field'}_$i\" value=\"$_e\">"
                    .(defined($l->[$i]) ? $l->[$i] : '')."</div>\n";
            }
        } elsif ($type eq 'select' || $field->{'enum'} || $field->{'label'}) {
            $input = "<select name=\"$field->{'field'}\" id=\"$field->{'field'}\">\n";
            my $e = $field->{'enum'}  || [];
            my $l = $field->{'label'} || $e;
            my $I = @$e > @$l ? $#$e : $#$l;
            for (my $i = 0; $i <= $I; $i++) {
                $input .= "    <option".(defined($e->[$i]) ? " value=\"".do { my $_e = $e->[$i]; $_e =~ s/\"/&quot;/g; $_e }.'"' : '').">"
                    .(defined($l->[$i]) ? $l->[$i] : '')."</option>\n";
            }
            $input .= "</select>\n";
        } else {
            my $s = $field->{'size'} ? " size=\"$field->{'size'}\"" : '';
            my $m = $field->{'maxlength'} || $field->{'max_len'}; $m = $m ? " maxlength=\"$m\"" : '';
            $input = "<input type=\"$type\" name=\"$field->{'field'}\" id=\"$field->{'field'}\"$s$m value=\"\" />";
        }

        $n++;
        my $copy = $args->{'row_template'};
        my $name = $field->{'field'};
        $name = $field->{'name'} || do { $name =~ tr/_/ /; $name =~ s/\b(\w)/\u$1/g; $name };
        $name = "<label for=\"$field->{'field'}\">$name</label>";
        $copy =~ s/\$field/$field->{'field'}/g;
        $copy =~ s/\$name/$name/g;
        $copy =~ s/\$input/$input/g;
        $copy =~ s/\$oddeven/$n % 2 ? 'odd' : 'even'/eg;
        $txt .= $copy;
    }
    $txt .= $args->{'footer'} . ($args->{'close'} || "</form>\n") . ($args->{'div_close'} || "</div>\n");
    if ($js) {
        local  @{ $val_hash }{('general form_args', 'group form_args')};
        delete @{ $val_hash }{('general form_args', 'group form_args')};
        $txt .= $self->generate_js($val_hash, $args);
    }
    return $txt;
}

###---------------------###
### How to handle errors

package CGI::Ex::Validate::Error;

use strict;
use overload '""' => \&as_string;

sub new {
    my ($class, $errors, $extra) = @_;
    die "Missing or invalid errors arrayref" if ref $errors ne 'ARRAY';
    die "Missing or invalid extra  hashref"  if ref $extra  ne 'HASH';
    return bless {errors => $errors, extra => $extra}, $class;
}

sub as_string {
    my $self = shift;
    my $extra  = $self->{extra} || {};
    my $extra2 = shift || {};

    # allow for formatting
    my $join = defined($extra2->{as_string_join}) ? $extra2->{as_string_join}
    : defined($extra->{as_string_join}) ? $extra->{as_string_join}
    : "\n";
    my $header = defined($extra2->{as_string_header}) ? $extra2->{as_string_header}
    : defined($extra->{as_string_header}) ? $extra->{as_string_header} : "";
    my $footer = defined($extra2->{as_string_footer}) ? $extra2->{as_string_footer}
    : defined($extra->{as_string_footer}) ? $extra->{as_string_footer} : "";

    return $header . join($join, @{ $self->as_array($extra2) }) . $footer;
}

sub as_array {
    my $self = shift;
    my $errors = $self->{errors} || die "Missing errors";
    my $extra  = $self->{extra}  || {};
    my $extra2 = shift || {};

    my $title = defined($extra2->{as_array_title}) ? $extra2->{as_array_title}
    : defined($extra->{as_array_title}) ? $extra->{as_array_title}
    : "Please correct the following items:";

    # if there are heading items then we may end up needing a prefix
    my $has_headings;
    if ($title) {
        $has_headings = 1;
    } else {
        foreach (@$errors) {
            next if ref;
            $has_headings = 1;
            last;
        }
    }

    my $prefix = defined($extra2->{as_array_prefix}) ? $extra2->{as_array_prefix}
    : defined($extra->{as_array_prefix}) ? $extra->{as_array_prefix}
    : $has_headings ? '  ' : '';

    # get the array ready
    my @array = ();
    push @array, $title if length $title;

    # add the errors
    my %found = ();
    foreach my $err (@$errors) {
        if (! ref $err) {
            push @array, $err;
            %found = ();
        } else {
            my $text = $self->get_error_text($err);
            next if $found{$text};
            $found{$text} = 1;
            push @array, "$prefix$text";
        }
    }

    return \@array;
}

sub as_hash {
    my $self = shift;
    my $errors = $self->{errors} || die "Missing errors";
    my $extra  = $self->{extra}  || {};
    my $extra2 = shift || {};

    my $suffix = defined($extra2->{as_hash_suffix}) ? $extra2->{as_hash_suffix}
    : defined($extra->{as_hash_suffix}) ? $extra->{as_hash_suffix} : '_error';
    my $join   = defined($extra2->{as_hash_join}) ? $extra2->{as_hash_join}
    : defined($extra->{as_hash_join}) ? $extra->{as_hash_join} : '<br />';

    my %found;
    my %return;
    foreach my $err (@$errors) {
        next if ! ref $err;

        my ($field, $type, $field_val, $ifs_match) = @$err;
        die "Missing field name" if ! $field;
        if ($field_val->{delegate_error}) {
            $field = $field_val->{delegate_error};
            $field =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
        }

        my $text = $self->get_error_text($err);
        next if $found{$field}->{$text};
        $found{$field}->{$text} = 1;

        $field .= $suffix;
        push @{ $return{$field} }, $text;
    }

    if ($join) {
        my $header = defined($extra2->{as_hash_header}) ? $extra2->{as_hash_header}
        : defined($extra->{as_hash_header}) ? $extra->{as_hash_header} : "";
        my $footer = defined($extra2->{as_hash_footer}) ? $extra2->{as_hash_footer}
        : defined($extra->{as_hash_footer}) ? $extra->{as_hash_footer} : "";
        foreach my $key (keys %return) {
            $return{$key} = $header . join($join,@{ $return{$key} }) . $footer;
        }
    }

    return \%return;
}

### return a user friendly error message
sub get_error_text {
    my $self  = shift;
    my $err   = shift;
    my $extra = $self->{extra} || {};
    my ($field, $type, $field_val, $ifs_match, $custom_err) = @$err;
    return $custom_err if defined($custom_err) && length($custom_err);
    my $dig     = ($type =~ s/(_?\d+)$//) ? $1 : '';
    my $type_lc = lc($type);

    # allow for delegated field names - only used for defaults
    if ($field_val->{delegate_error}) {
        $field = $field_val->{delegate_error};
        $field =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
    }

    # the the name of this thing
    my $name = $field_val->{'name'};
    $name = "The field $field" if ! $name && ($field =~ /\W/ || ($field =~ /\d/ && $field =~ /\D/));
    if (! $name) {
        $name = $field;
        $name =~ tr/_/ /;
        $name =~ s/\b(\w)/\u$1/g;
    }
    $name =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;

    # type can look like "required" or "required2" or "required100023"
    # allow for fallback from required100023_error through required_error

    # look in the passed hash or self first
    my $return;
    foreach my $key ((length($dig) ? "${type}${dig}_error" : ()), "${type}_error", 'error') {
        $return = $field_val->{$key} || $extra->{$key} || next;
        $return =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
        $return =~ s/\$field/$field/g;
        $return =~ s/\$name/$name/g;
        if (my $value = $field_val->{"$type$dig"}) {
            $return =~ s/\$value/$value/g if ! ref $value;
        }
        last;
    }

    # set default messages
    if (! $return) {
        if ($type eq 'required' || $type eq 'required_if') {
            $return = "$name is required.";

        } elsif ($type eq 'min_values') {
            my $n = $field_val->{"min_values${dig}"};
            my $values = ($n == 1) ? 'value' : 'values';
            $return = "$name had less than $n $values.";

        } elsif ($type eq 'max_values') {
            my $n = $field_val->{"max_values${dig}"};
            my $values = ($n == 1) ? 'value' : 'values';
            $return = "$name had more than $n $values.";

        } elsif ($type eq 'enum') {
            $return = "$name is not in the given list.";

        } elsif ($type eq 'equals') {
            my $field2 = $field_val->{"equals${dig}"};
            my $name2  = $field_val->{"equals${dig}_name"} || "the field $field2";
            $name2 =~ s/\$(\d+)/defined($ifs_match->[$1]) ? $ifs_match->[$1] : ''/eg if $ifs_match;
            $return = "$name did not equal $name2.";

        } elsif ($type eq 'min_len') {
            my $n = $field_val->{"min_len${dig}"};
            my $char = ($n == 1) ? 'character' : 'characters';
            $return = "$name was less than $n $char.";

        } elsif ($type eq 'max_len') {
            my $n = $field_val->{"max_len${dig}"};
            my $char = ($n == 1) ? 'character' : 'characters';
            $return = "$name was more than $n $char.";

        } elsif ($type eq 'max_in_set') {
            my $set = $field_val->{"max_in_set${dig}"};
            $return = "Too many fields were chosen from the set ($set)";

        } elsif ($type eq 'min_in_set') {
            my $set = $field_val->{"min_in_set${dig}"};
            $return = "Not enough fields were chosen from the set ($set)";

        } elsif ($type eq 'match') {
            $return = "$name contains invalid characters.";

        } elsif ($type eq 'compare') {
            $return = "$name did not fit comparison.";

        } elsif ($type eq 'sql') {
            $return = "$name did not match sql test.";

        } elsif ($type eq 'custom') {
            $return = "$name did not match custom test.";

        } elsif ($type eq 'type') {
            my $_type = $field_val->{"type${dig}"};
            $return = "$name did not match type $_type.";

        } elsif ($type eq 'untaint') {
            $return = "$name cannot be untainted without one of the following checks: enum, equals, match, compare, sql, type, custom";

        } elsif ($type eq 'no_extra_fields') {
            $return = "$name should not be passed to validate.";
        }
    }

    die "Missing error on field $field for type $type$dig" if ! $return;
    return $return;

}

1;

### See the perldoc in CGI/Ex/Validate.pod
