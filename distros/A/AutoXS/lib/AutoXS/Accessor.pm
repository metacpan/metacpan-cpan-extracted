package AutoXS::Accessor;

use 5.008;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.03';

BEGIN { require AutoXS; }
use base 'AutoXS';

use B qw( svref_2object );
use B::Utils qw( opgrep op_or );
use Class::XSAccessor;

CHECK {
  warn "Running AutoXS scanner of " . __PACKAGE__ if $AutoXS::Debug;
  __PACKAGE__->scan_package_accessor($_) for keys %{$AutoXS::ScanClasses{"".__PACKAGE__}};
}

sub scan_package_accessor {
  my $selfclass = shift;
  my $edit_pkg = shift;
  warn "Scanning package '$edit_pkg'" if $AutoXS::Debug;

  my $sym = $selfclass->get_symbol($edit_pkg);

  my @to_be_replaced;

  foreach my $function (sort keys %$sym) {
    next if $function =~ /^BEGIN|END|CHECK|UNITCHECK|INIT|import$/;
    warn "Scanning function '${edit_pkg}::$function'" if $AutoXS::Debug;

    local *symbol = $sym->{$function};
    my $coderef = *symbol{CODE} or next;

    my $codeobj = svref_2object($coderef);
    next unless ref $codeobj eq 'B::CV';
    if ($codeobj->XSUB) {
      #print *symbol, " is XS\n";
    }
    else {
      my $r = $codeobj->ROOT;
      my $glob_array_dereference = {
        name => 'rv2av',
        first => { name => 'gv', },
      };

      my $array_hash_access_or_shift = {
        name => 'helem',
        first => {
          name => 'rv2hv',
          first => op_or(
            { name => 'aelem',
              first => $glob_array_dereference,
              'last' => { name => 'const', },
            },
            { name => 'shift',
              first => $glob_array_dereference,
            },
          ),
        },
        'last' => { name => 'const', },
      };
      my $simple_structure = {
        name => 'lineseq',
        kids => [
          { name => 'nextstate', },
          op_or(
            { name => 'return',
              first => {name => 'pushmark'},
              'last' => $array_hash_access_or_shift,
            },
            $array_hash_access_or_shift,
          ),
        ],
      };
      my $hash_access_pad = {
        name => 'helem',
        first => {
          name => 'rv2hv',
          first => { name => 'padsv' },              
        },
        last => {
          name => 'const',
          capture => 'hash_key',
        },
      };

      my $self_shift_structure = {
        name => 'lineseq',
        kids => [
          { name => 'nextstate', },
          { name => 'sassign', # optionally match my $self = shift and friends
            first => {
              name => 'shift',
              first => $glob_array_dereference,
            },
          },
          { name => 'nextstate', },
          op_or(
            { name => 'return',
              first => {name => 'pushmark'},
              'last' => $hash_access_pad,
            },
            $hash_access_pad,
          ),
        ],
      };

      my $self_array_assign_structure = {
        name => 'lineseq',
        kids => [
          { name => 'nextstate', },
          { name => 'aassign',
            kids => [
              { name => 'null',
                first => {
                  name => 'pushmark',
                  sibling => op_or(
                    $glob_array_dereference,
                    { name => 'shift',
                      first => $glob_array_dereference,
                    },
                  ),
                },
              },
              { name => 'null',
                first => {
                  name => 'pushmark',
                  sibling => {name => 'padsv'}
                },
              },
            ],
          },
          { name => 'nextstate', },
          op_or(
            { name => 'return',
              first => {name => 'pushmark'},
              'last' => $hash_access_pad,
            },
            $hash_access_pad,
          ),
        ],
      };
      B::Utils::walkoptree_filtered(
        $r,
        sub { opgrep( {
          name => 'leavesub',
          first => op_or(
            $simple_structure,
            $self_shift_structure,
            $self_array_assign_structure,
          ),
        }, @_ ) },
        sub {
          my $op = shift;
          #print $op->name." " .$op->type." " .$op->first->name. "\n";
          #my $inner = $op->first->last;
          #$inner = $inner->last if $inner->name eq 'return';
          #$inner = $inner->last;
          #my $key_string = $inner->sv->PV;
          my $key_string = $op->{hash_key}->sv->PV;
          #warn $key;
          push @to_be_replaced, ["${edit_pkg}::$function", $key_string];
        },
      );
    }
  }

  foreach my $struct (@to_be_replaced) {
    my $function = $struct->[0];
    my $key = $struct->[1];
    if ($AutoXS::Debug) {
      warn "Replacing $function with XS accessor for key '$key'.\n";
    }
    Class::XSAccessor->import(
      replace => 1,
      getters => { $function => $key },
    );
  }

}

1;
__END__

=head1 NAME

AutoXS::Accessor - Identify accessors and replace them with XS

=head1 SYNOPSIS
  
  package MyClass;
  use AutoXS plugins => 'Accessor';
  
  # or load all installed optimizing plugins
  use AutoXS ':all';
  
  sub new {...}
  sub get_foo { $_[0]->{foo} }
  sub other_stuff {...}
  
  # get_foo will be auto-replaced with XS and faster

=head1 DESCRIPTION

This is an example plugin module for the L<AutoXS> module. It searches
the user package (C<MyClass> above) for read-only accessor methods of certain forms
and replaces them with faster XS code.

=head1 RECOGNIZED ACCESSORS

Note that whitespace, a trailing semicolon, and the method names don't matter.
Also please realize that this is B<not a source filter>.

  sub get_acc { $_[0]->{acc} }
  
  sub get_bcc {
    my $self = shift;
    $self->{bcc}
  }
  
  sub get_ccc {
    my $self = shift;
    return $self->{ccc};
  }
  
  sub get_dcc { return $_[0]->{dcc} }
  
  sub get_ecc { shift->{ecc} }
  
  sub get_fcc {
    my ($self) = @_;
    $self->{fcc}
  }
  
  sub get_gcc {
    my ($self) = @_;
    return $self->{gcc};
  }
  
  sub get_icc {
    my ($self) = shift;
    $self->{icc}
  }
  
  sub get_jcc {
    my ($self) = shift;
    return $self->{jcc};
  }

=head1 SEE ALSO

L<AutoXS>

L<Class::XSAccessor>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

