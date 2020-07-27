use strict;
use warnings;

#ABSTRACT: A role that defines the interface to a hashing algorithm
#

package Archive::BagIt::Role::Algorithm;

use Moo::Role;
with 'Archive::BagIt::Role::Plugin';

has 'name' => (
    is => 'ro',
);


sub get_hash_string {
    my ($self, $fh) = @_;
    return;
}

sub verify_file {
    my ($self, $fh) = @_;
    return;
}

sub register_plugin {
    my ($class, $bagit) =@_;
    my $self = $class->new({bagit=>$bagit});
    my $plugin_name = $self->plugin_name;
    $self->bagit->plugins( { $plugin_name => $self });
    $self->bagit->algos( {$self->name => $self });
    return 1;
}
no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Algorithm - A role that defines the interface to a hashing algorithm

=head1 VERSION

version 0.059

=head1 NAME

Archive::BagIt::Role::Algorithm - A role that defines the interface to a hashing algorithm

=head1 VERSION

version 0.059

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<https://github.com/Archive-BagIt>
and may be cloned from L<git://github.com/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
