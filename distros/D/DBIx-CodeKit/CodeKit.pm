package DBIx::CodeKit;

use strict;
use warnings;
use Carp;

use vars qw( $VERSION );
$VERSION = '1.07';

=head1 NAME

DBIx::CodeKit - Universal Code Table Interface

=head1 SYNOPSIS

  use DBIx::CodeKit;
 
  my $ck = new DBIx::CodeKit($dbh,
                 table     => 'ck_code',
                 getparam  => sub { $cgi->param(shift) },
                 getparams => sub { $cgi->param(shift.'[]') }
                 );

=cut

###  See the rest of the pod documentation at the end of this file.  ###

sub new {
    my $class = shift;
    my $dbh = shift;
    my $args = ref($_[0]) ? shift : { @_ };
    my $self = {};
    bless $self, $class;

    croak 'DBIx::CodeKit->new($dbh): $dbh is not an object' unless ref $dbh;
    $self->{dbh} = $dbh;

    $self->{table}     = $args->{table} || 'ck_code';
    $self->{getparam}  = $args->{getparam};
    $self->{getparams} = $args->{getparams};

    return $self;
}


# # #  HTML display methods.

sub desc {
    my $self = shift;
    return &htmlspecialchars( $self->data(@_) );
}

sub ucfirst {
    my $self = shift;
    return CORE::ucfirst( $self->desc(@_) );
}

sub ucwords {
    my $self = shift;
    my $str = $self->desc(@_);
    $str =~ s/(^|\s)([a-z])/$1\u$2/g;
    return $str;
}


# # #  Data methods.

sub data {
    my $self = shift;
    my $code_set = shift;
    my $code_code = shift;
    $code_code .= '';   # DBI needs strings here.
    $self->{data_sth} = $self->{dbh}->prepare("
        select  code_desc
        from    $self->{table}
        where   code_set  = ?
        and     code_code = ?
    ") unless $self->{data_sth};
    $self->{data_sth}->execute($code_set, $code_code);
    my $code_desc = $self->{data_sth}->fetchrow;
    $code_desc = '' unless defined $code_desc; # Avoid warnings.
    return $code_desc;
}


# # #  HTML select single value methods:

sub select {
    my $self = shift;
    my $code_set = shift;
    my $args = ref($_[0]) ? shift : { @_ };

    my $var_name      = $args->{var_name} || $code_set;
    my $value         = $args->{value};
    my $default       = $args->{default};
    my $subset        = $args->{subset};
    my $options       = $args->{options};
    my $select_prompt = $args->{select_prompt};
    my $blank_prompt  = $args->{blank_prompt};

    # Variable setup.
    $value            = $self->_getparam($var_name, $value, $default);
    my $Subset        = &keyme($subset);
    $options          = $options ? " $options" : '';
    $select_prompt    = '' unless defined $select_prompt;
    $blank_prompt     = '' unless defined $blank_prompt;

    # Drop down box.
    my $select = "<select name=\"$var_name\"$options>\n";

    # Blank options.
    my $selected = '';
    if ($value eq '') {
        if ($select_prompt eq '') {
            $select_prompt =
                $self->ucwords('code_set', $code_set) . '?';
        }
        $select .= "<option value=\"\" selected>$select_prompt\n";
        $selected = 1;
    } elsif ($blank_prompt ne '') {
        $select .= "<option value=\"\">$blank_prompt\n";
    }

    # Show code set options.
    my $set_list = $self->code_set($code_set);
    for my $row ( @$set_list ) {
        my ($code_code, $code_desc) = @$row;
        next if ($Subset && !$Subset->{$code_code} && $code_code ne $value);
        $code_desc = htmlspecialchars(CORE::ucfirst($code_desc));

        if ($code_code eq $value) {
            $selected = 1;
            $select .= "<option value=\"$code_code\" selected>$code_desc\n";
        } elsif ($row->[3] ne 'd') {
            $select .= "<option value=\"$code_code\">$code_desc\n";
        }
    }

    # Show a missing value.
    if (!$selected) {
        $select .= "<option value=\"$value\" selected>$value\n";
    }

    $select .= "</select>\n";
    return $select;
}

sub radio {
    my $self = shift;
    my $code_set = shift;
    my $args = ref($_[0]) ? shift : { @_ };

    my $var_name      = $args->{var_name} || $code_set;
    my $value         = $args->{value};
    my $default       = $args->{default};
    my $subset        = $args->{subset};
    my $options       = $args->{options};
    my $blank_prompt  = $args->{blank_prompt};
    my $sep           = $args->{sep};

    # Variable setup.
    $value            = $self->_getparam($var_name, $value, $default);
    my $Subset        = &keyme($subset);
    $options          = $options ? " $options" : '';
    $blank_prompt     = '' unless defined $blank_prompt;
    $sep              = "<br>\n" unless defined $sep;

    # Blank options.
    my $select = '';
    my $selected = '';
    if ($value eq '') {
        $selected = 1;
        if ($blank_prompt ne '') {
            $select .= "<input type=\"radio\" name=\"$var_name\"$options";
            $select .= " value=\"\" checked>$blank_prompt";
        }
    } else {
        if ($blank_prompt ne '') {
            $select .= "<input type=\"radio\" name=\"$var_name\"$options";
            $select .= " value=\"\">$blank_prompt";
        }
    }

    # Show code set options.
    my $set_list = $self->code_set($code_set);
    for my $row ( @$set_list ) {
        my ($code_code, $code_desc) = @$row;
        next if ($Subset && !$Subset->{$code_code} && $code_code ne $value);
        $code_desc = htmlspecialchars(CORE::ucfirst($code_desc));
        if ( $code_code eq $value ) {
            $selected = 1;
            $select .= $sep if $select;
            $select .= "<input type=\"radio\" name=\"$var_name\"$options";
            $select .= " value=\"$code_code\" checked>$code_desc";
        } elsif ($row->[3] ne 'd') {
            $select .= $sep if $select;
            $select .= "<input type=\"radio\" name=\"$var_name\"$options";
            $select .= " value=\"$code_code\">$code_desc";
        }
    }

    # Show missing values.
    if (!$selected) {
        $select .= $sep if $select;
        $select .= "<input type=\"radio\" name=\"$var_name\"$options";
        $select .= " value=\"$value\" checked>$value";
    }

    return $select;
}


# # #  HTML select multiple value methods:

sub multiple {
    my $self = shift;
    my $code_set = shift;
    my $args = ref($_[0]) ? shift : { @_ };

    my $var_name      = $args->{var_name} || $code_set;
    my $value         = $args->{value};
    my $default       = $args->{default};
    my $subset        = $args->{subset};
    my $options       = $args->{options};
    my $size          = $args->{size};

    # Variable setup.
    my $Value         = $self->_getparams($var_name, $value, $default);
    my $Subset        = &keyme($subset);
    $options          = $options ? " $options" : '';

    # Select multiple box.
    my $select = "<select multiple name=\"$var_name"."[]\"$options";
    $select .= " size=\"$size\"" if ($size);
    $select .= ">\n";

    # Show code set options.
    my $set_list = $self->code_set($code_set);
    for my $row ( @$set_list ) {
        my ($code_code, $code_desc) = @$row;
        next if ($Subset && !$Subset->{$code_code} && !$Value->{$code_code});
        $code_desc = htmlspecialchars(CORE::ucfirst($code_desc));
        if ( $Value->{$code_code} ) {
            $select .= "<option value=\"$code_code\" selected>$code_desc\n";
            delete $Value->{$code_code};
        } elsif ($row->[3] ne 'd') {
            $select .= "<option value=\"$code_code\">$code_desc\n";
        }
    }

    # Show missing values.
    for my $code_code ( keys %$Value ) {
        $select .= "<option value=\"$code_code\" selected>$code_code\n";
    }

    $select .= "</select>\n";
    return $select;
}

sub checkbox {
    my $self = shift;
    my $code_set = shift;
    my $args = ref($_[0]) ? shift : { @_ };

    my $var_name      = $args->{var_name} || $code_set;
    my $value         = $args->{value};
    my $default       = $args->{default};
    my $subset        = $args->{subset};
    my $options       = $args->{options};
    my $sep           = $args->{sep};

    # Variable setup.
    my $Value         = $self->_getparams($var_name, $value, $default);
    my $Subset        = &keyme($subset);
    $options          = $options ? " $options" : '';
    $sep              = "<br>\n" unless defined $sep;

    # Show code set options.
    my $select;
    my $set_list = $self->code_set($code_set);
    for my $row ( @$set_list ) {
        my ($code_code, $code_desc) = @$row;
        next if ($Subset && !$Subset->{$code_code} && !$Value->{$code_code});
        $code_desc = htmlspecialchars(CORE::ucfirst($code_desc));
        if ( $Value->{$code_code} ) {
            $select .= $sep if $select;
            $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
            $select .= "$options value=\"$code_code\" checked>$code_desc";
            delete $Value->{$code_code};
        } elsif ($row->[3] ne 'd') {
            $select .= $sep if $select;
            $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
            $select .= "$options value=\"$code_code\">$code_desc";
        }
    }

    # Show missing values.
    for my $code_code ( keys %$Value ) {
        $select .= $sep if $select;
        $select .= "<input type=\"checkbox\" name=\"$var_name"."[]\"";
        $select .= "$options value=\"$code_code\" checked>$code_code";
    }

    return $select;
}


# # #  Code Set Methods.

sub code_set {
    my $self = shift;
    my $code_set = shift;
    $self->{set_sth} = $self->{dbh}->prepare("
        select  code_code,
                code_desc,
                code_order,
                code_flag
        from    $self->{table}
        where   code_set = ?
        order by code_order, code_code
    ") unless $self->{set_sth};
    $self->{set_sth}->execute($code_set);
    return $self->{set_sth}->fetchall_arrayref;
}


# # #  Code Table Updates.

sub remove {
    my $self       = shift;
    my $code_set   = shift;
    my $code_code  = shift;
    $code_code .= '';   # DBI needs strings here.
    $self->{remove_sth} = $self->{dbh}->prepare("
        delete from $self->{table}
        where   code_set  = ?
        and     code_code = ?
    ") unless $self->{remove_sth};
    $self->{remove_sth}->execute($code_set, $code_code);
}

sub get {
    my $self       = shift;
    my $code_set   = shift;
    my $code_code  = shift;
    $self->{get_sth} = $self->{dbh}->prepare("
        select  code_desc,
                code_order,
                code_flag
        from    $self->{table}
        where   code_set  = ?
        and     code_code = ?
    ") unless $self->{get_sth};
    $self->{get_sth}->execute($code_set, $code_code);
    my @info = $self->{get_sth}->fetchrow_array;
    return @info;
}

sub put {
    my $self       = shift;
    my $code_set   = shift;
    my $code_code  = shift;
    my $code_desc  = shift;
    my $code_order = shift;
    my $code_flag  = shift;

    # Get the existing code info, if any.
    my @old = $self->get($code_set, $code_code);

    # Field work.
    $code_code  .= '';   # DBI needs strings here.
    $code_desc  .= '';
    if (!@old and
        ( not defined($code_order) or $code_order eq '' )
        and $code_code =~ /^\d+$/) {
        $code_order = $code_code;
    }
    { # Argument "" isn't numeric in int.  Isn't that int's job?
        no warnings;
        $code_order  = int($code_order);
    }
    $code_flag  .= '';

    # Make it so: add, update, or delete.
    if (@old) {
        my ( $old_desc, $old_order, $old_flag ) = @old;
        if ($code_desc ne '') {
            if ($code_desc  ne $old_desc ||
                $code_order ne $old_order ||
                $code_flag  ne $old_flag) {
                $self->_update($code_set, $code_code,
                            $code_desc, $code_order, $code_flag);
            }
        }
        else {
            $self->remove($code_set, $code_code);
        }
    }
    elsif ($code_desc ne '') {
        $self->_insert($code_set, $code_code,
                    $code_desc, $code_order, $code_flag);
    }
}


# # #  Private methods.

sub _insert {
    my $self = shift;
    $self->{insert_sth} = $self->{dbh}->prepare("
        insert into $self->{table} set
            code_set   = ?,
            code_code  = ?,
            code_desc  = ?,
            code_order = ?,
            code_flag  = ?
    ") unless $self->{insert_sth};
    $self->{insert_sth}->execute(@_);
}

sub _update {
    my $self       = shift;
    my $code_set   = shift;
    my $code_code  = shift;
    my $code_desc  = shift;
    my $code_order = shift;
    my $code_flag  = shift;
    $self->{update_sth} = $self->{dbh}->prepare("
        update $self->{table} set
                code_desc  = ?,
                code_order = ?,
                code_flag  = ?
        where   code_set   = ?
        and     code_code  = ?
    ") unless $self->{update_sth};
    $self->{update_sth}->execute(
        $code_desc,
        $code_order,
        $code_flag,
        $code_set,
        $code_code
    );
}

sub _getparam {
    my $self = shift;
    my $var_name = shift;
    my $value = shift;
    my $default = shift;
    if ( not defined $value ) {
        if ( $self->{getparam} ) {
            $value = &{$self->{getparam}}($var_name);
        }
        $value = $default unless defined $value;
        $value = '' unless defined $value;
    }
    return $value;
}

sub _getparams {
    my $self = shift;
    my $var_name = shift;
    my $value = shift;
    my $default = shift;
    if ( not defined $value ) {
        my $call = $self->{getparams} ? $self->{getparams} : $self->{getparam};
        if ( $call ) {
            $value = [ grep { defined $_ } &$call($var_name) ];
            $value = $value->[0] if ref $value->[0];
        }
        $value = $default unless defined $value;
        $value = '' unless defined $value;
    }
    return &keyme($value) || {};
}

sub keyme {
    my $value = shift;
    return $value if ref($value) eq 'HASH';
    my $Keyhash;
    if (ref($value) eq 'ARRAY') {
        for my $val ( @$value ) { $Keyhash->{$val} = 1; }
    } elsif (defined($value) && $value ne '' && !ref($value)) {
        $Keyhash->{$value} = 1;
    }
    return $Keyhash;
}

sub htmlspecialchars {
    my $str = shift;
    $str =~ s/&/\&amp;/g;
    $str =~ s/"/\&quot;/g;
    $str =~ s/</\&lt;/g;
    $str =~ s/>/\&gt;/g;
    return $str;
}

1;

__END__
 
=head2 Get code descriptions safe for HTML display
  
  $str = $ck->desc(   $code_set, $code_code);
  $str = $ck->ucfirst($code_set, $code_code);
  $str = $ck->ucwords($code_set, $code_code);
 
=head2 Get code descriptions not safe for HTML display
 
  $str = $ck->data(  $code_set, $code_code);
 
=head2 HTML select common options
 
         var_name      => 'start_day'
         value         => $start_day
         default       => 1
         subset        => [ 1, 2, 3, 4, 5 ]
         options       => 'onchange="submit()"'
 
=head2 HTML select single value methods
  
  $str = $ck->select($code_set,
         select_prompt => "Code set description?",
         blank_prompt  => "None"
         );
 
  $str = $ck->radio($code_set,
         blank_prompt  => "None",
         sep           => "<br>\n"
         );
 
=head2 HTML select multiple value methods
 
  $str = $ck->multiple($code_set,
         size          => 10
         );
 
  $str = $ck->checkbox($code_set,
         sep           => "<br>\n"
         );
 
=head2 Code sets
 
  $rows = $ck->code_set($code_set);
 
=head2 Code table updates
  
  $ck->remove($code_set, $code_code);
 
  ( $code_desc, $code_order, $code_flag ) =
    $ck->get($code_set, $code_code);
 
  $ck->put($code_set, $code_code,
           $code_desc, $code_order, $code_flag);
 
=head1 DESCRIPTION

CodeKit is an interface to a universal database code table.
CodeKit takes all of the programming work out of maintaining
multiple database code definition sets.

The code administration page lets you define new virtual
code tables and enter all codes and their descriptions.
Perl and PHP classes retrieve the code descriptions and
automatically generate HTML code selection elements.

For news and updates visit the CodeKit home page:

http://www.webbysoft.com/codekit

=head1 SEE ALSO

For a full featured multilingual universal code table
visit the BabelKit home page:

http://www.webbysoft.com/babelkit

=head1 AUTHOR

Contact John Gorman at http://www.webbysoft.com
to report bugs, request features, or for database
design and programming assistance.

=head1 COPYRIGHT

Copyright (C) 2003 John Gorman.  All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl or the LGPL.
