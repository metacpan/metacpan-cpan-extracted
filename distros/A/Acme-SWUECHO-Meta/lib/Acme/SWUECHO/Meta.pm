package Acme::SWUECHO::Meta;

use strict;
use 5.008_005;
our $VERSION = '0.02';
use PPI;
use Carp;
use Pod::Simple::Search;
use Exporter::Auto;


sub subs_in_current_pkg {
    my $module = caller;
    no strict 'refs';
    grep { defined *{"${module}::$_"}{CODE} } keys %{"${module}::"};
    
    # &{"${module}::$_"} equal to  defined *{"$module\::$_"}{CODE}
    # why \::?
    
}

## TOOD: better ways to find module path
sub module_path {
    my $module = shift;

    # From This::That to This/That.pm
    s/::/\//g, s/$/.pm/ for $module;
    require $module ;
    $INC{$module} ;
}



sub subs_in_pkg {
    my %all_sub;
    my $doc = PPI::Document->new(module_path(shift)) or croak 'no package name are given';
    my $subs = $doc->find('PPI::Statement::Sub');
    for my $sub ( @{$subs} ) {
        $all_sub{ $sub->name } = $sub->content    # unless $sub->forward ;
    }

    keys %all_sub;
}



1;
__END__

=encoding utf-8

=head1 NAME

Acme::SWUECHO::Meta - a set of tool to learn modules.



=head1 SYNOPSIS

  use Acme::SWUECHO::Meta;
  methods_in_current_pkg

=head1 DESCRIPTION

Acme::SWUECHO::Meta is a set of tool to learn modules.
This is a Acme package, but no one can stop you from using it.

=head2 methods_in_current_pkg

	@methods = methods_in_current_pkg;

find all the method imported in current package. 
you can get the information from the doc, but not always.
However, you can alway get the information from the source code.

The typical usage is to know what methods or funciton are available after you C<use module> in your script.


copied from

http://stackoverflow.com/questions/607282/whats-the-best-way-to-discover-all-subroutines-a-perl-module-has

=head2 module_path

	$module_path = module_path($module);

find the module path

=head2 subs_in_pkg

	@methods = subs_in_pkg($module);

this is a method using PPI to do the work, so no need to run the acutual module, but it only include the method 
find in the module_path.


=head1 AUTHOR

Hao Wu E<lt>echowuhao@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Hao Wu

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
