package AutoCode::SymbolTableUtils;
use strict;
# It is right NOT to let this package inhert anything.


sub st_by_object {
    my ($object)=@_;
    no strict 'refs';
    foreach my $symbol(keys %{"$object\::"}){
        print "$symbol\n";
        my $full_name="$object\::$symbol";
        foreach(qw(SCALAR ARRAY HASH CODE GLOB IO)){
            if(defined (*$full_name{$_})){
                print "\t$_\t". ${*$full_name{$_}} ."\n";
            }
        }
        print ${"$object\::$symbol"}, "\n";
        print @{"$object\::$symbol"}, "\n";
        print "CODE: ". &{"$object\::$symbol"}, "\n" if defined &{"$object\::$symbol"};
    }
}

sub return_deref {
    my ($symbol, $ref)=@_;
    my %ref_prefix=(
        SCALAR => '$',
        ARRAY => '@',
        HASH => '%',
        CODE => '&',
        GLOB => '*'
    );
    my $prefix=$ref_prefix{$ref};
    unless(defined $prefix){
        ; # something is warning
    }

    my $eval="${prefix}$symbol";
    return eval($eval);
    if($ref eq 'SCALAR'){
        $$symbol;
    }elsif($ref eq 'ARRAY'){
        @$symbol;
    }elsif($ref eq 'HASH'){
        %$symbol;
    }elsif($ref eq 'CODE'){
        &$symbol;
    }elsif($ref eq 'GLOB'){
        *$symbol;
    }
}

sub listsub {
    my ($obj)=@_;
    my $pkg = ref($obj) || $obj;
    __PACKAGE__->_load_module($pkg);
    my @subs;
    no strict 'refs';
    foreach (keys %{"$pkg\::"}){
        push @subs, $_ if defined &$_;
    }
    return @subs;
}

sub PKG_exists_in_ST {
    my ($pkg) = @_;
    no strict 'refs';
    return (scalar keys %{"$pkg\::"});
}

# There are more than one way to do such.
# $glob='AutoSQL::Root::new'
# no strict 'refs';
# defined *{$glob}{CODE};   # Way 1
# defined &{$glob};         # Way 2
sub CODE_exists_in_ST {
    my ($glob)=@_;
    no strict 'refs';
    return defined &$glob; 
}


# There are differences between defined *{$glob}{CODE}; and defined &$glob;
#
# If $glob is a string, e.g. a scalar, then ,,,,,,
*detect_sub_in_symbol_table = \&CODE_exists_in_ST;
*code_exists=\&CODE_exists_in_ST; 

sub CODE_exists {
    my $glob = shift;
    return defined &$glob;
}

sub ARRAY_exists {
    my $glob=shift;
    return defined &$glob;
}

1;

__END__

=head1 NAME



=head1 SYNOPSIS

  # Supposed you have a module 'A' with its only method 'a'
  use A;
  print AutoCode::SymbolTableUtils::code_exists('A::a')?'yes':'no' , "\n";
  

=head1 DESCRIPTION

I hope this module is enough for spying the every bit of Perl's symbol table.

The methods are categoried to answer 2 types of questions

=over 4 

=item * What are in the module or symbol table?

=item * Is something in the module or symbol table?

  PKG_exists
  CODE_exists
  
=back

=head1 AUTHOR

Juguang Xiao, juguang at tll.org.sg

=head1 COPYRIGHT

This module is a free software.
You may copy or redistribute it under the same terms as Perl itself.

=cut


