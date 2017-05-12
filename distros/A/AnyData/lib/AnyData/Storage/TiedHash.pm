######################################
package AnyData::Storage::TiedHash;
######################################
use strict;
use warnings;

sub FETCH {
    my($self,$key) = @_;
    my(@rows,$row,$found);
    return $self->{ad}->col_names if($key eq '__colnames');
    return $self->{ad}->key_col if $key eq '__key';
    my $ismultiple = ref $key;
    $self->{ad}->seek_first_record;
    while ($row = $self->{ad}->fetchrow_hashref) {
        if ( $self->{ad}->match($row,$key) ) {
            $found++;
            last unless $ismultiple;
            push @rows, $row;
        }
    }
    return \@rows if $ismultiple;
    return $found ? $row : undef;
}

sub TIEHASH {
    my $class   = shift;
    my $ad      = shift;
    my $perms   = shift || 'r';
    my $records = shift || {};
    my $self = {
        INDEX         => 0,
        RECORDS       => $records,
        ad            => $ad,
        del_marker    => "\0",
        needs_packing => 0,
        PERMS         => $perms,
    };
    return bless $self, $class;
}

sub verify_columns {
    my $col_names = shift;
    my $val       = shift;
    my %is_col = map {$_ => 1} @$col_names;
    my $errstr =  "ERROR: XXX is not a column in the table!\n";
    $errstr .= scalar @$col_names
            ? "       columns are: " . join "~",@$col_names,"\n"
            : "       couldn't find any column names\n";
    if (ref $val eq 'HASH') {
        for (keys %$val) {
             $errstr =~ s/XXX/$_/;
             die $errstr if !$is_col{$_};
        }
    }
    else {
        $errstr =~ s/XXX/$val/;
        $is_col{$val}
            ? return 1
            : die $errstr;
    }
}

sub STORE {
    my($self,$key,$value) = @_;
    #my @c = caller 1;
    $self->{errstr} = "Can't store: file is opened in 'r' read-only mode!"
        if $self->{PERMS} eq 'r';
    return undef if $self->{errstr};
    my @colnames = @{ $self->{ad}->col_names };
    verify_columns(\@colnames,$value);
    return $self->{ad}->update_multiple_rows($key,$value)
        if ref $key eq 'HASH';
    $self->{ad}->seek(0,2);
    my @newrow;
    for my $i(0..$#colnames) {
        $newrow[$i] = $value->{$colnames[$i]};
        next if defined $newrow[$i];
        $newrow[$i] = $key if $colnames[$i] eq $self->{ad}->key_col;
        $newrow[$i] = undef unless $newrow[$i];
    }
    return $self->{ad}->push_row(@newrow);
}

sub DELETE {
    my($self,$key)=@_;
    die "Can't delete: file is opened in 'r' read-only mode!"
        if $self->{PERMS} eq 'r';
    my $row;
    my $count;
    return $self->{ad}->delete_multiple_rows($key) if ref $key;
    if ($row = $self->FETCH($key) ) {
        $self->{ad}->delete_single_row;
        $self->{needs_packing}++;
        $count++;
    }
    #return $row;
    return $count;
}

sub EXISTS {
    my($self,$key)=@_;
    return $self->FETCH($key);
}

sub FIRSTKEY {
    my $self = shift;
    $self->{ad}->seek_first_record();
    my $found =0;
    my $row;
    while (!$found) {
        $row = $self->{ad}->fetchrow_hashref() or last;
        $found++;
        last;
    }
    return $found ? $row : undef;
}

sub NEXTKEY {
    my $self = shift;
    my $row;
    my $lastcol=0;
    my $found=0;
    while (!$found) {
        $row = $self->{ad}->fetchrow_hashref() or last;
        $found++;
        last;
    }
    return $found ? $row : undef;
}

sub adRows {
    my $self = shift;
    my $key  = shift;
    my $count=0;
    $self->{ad}->seek_first_record;
    if (!$key) {
        while (my $row = $self->{ad}->fetchrow_hashref) {
            $count++;
        }
    }
    else {
        while (my $row = $self->{ad}->fetchrow_hashref) {
            $count++ if $self->{ad}->match($row,$key);
        }
    }
    return $count;
}

sub adColumn {
    my($self,$column,$flags)=@_;
    $flags ||= '';
    my @results=();
    $self->{ad}->seek_first_record;
    while (my $row = $self->{ad}->fetchrow_hashref) {
        push @results, $row->{$column}
    }
    my %is_member;
    @results = grep(!$is_member{$_}++, @results) if $flags; $flags =~ /u/i;
#    @results = sort @results if $flags =~ /a/i;
#    @results = reverse sort @results if $flags =~ /d/i;
    return @results;
}

sub DESTROY {
    #my $self=shift;
    #undef $self->{ad};
    #print "HASH DESTROYED";
}
##############################
# END OF AnyData::Tiedhash
##############################
1;
