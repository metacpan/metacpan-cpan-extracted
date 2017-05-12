package App::Presto::CommandFactory;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::CommandFactory::VERSION = '0.010';
# ABSTRACT: Responsible for installing all commands

use Moo;
use Module::Pluggable require => 1, sub_name => 'commands', search_path => ['App::Presto::Command'];

sub install_commands {
    my $self = shift;
    my $ctx = shift;
    foreach my $command_module($self->commands){
        my $command = $command_module->new( context => $ctx );
        $command->install;
    }
    return;
}

sub help_categories {
    my $self = shift;
    my %categories;
    foreach my $command_module($self->commands){
        if($command_module->does('App::Presto::CommandHasHelp') ){
            (my $short_module = $command_module) =~ s/^.*::Command:://;
            $short_module =~ s/::/-/g;
            $categories{$short_module} = $command_module->help_categories;
        }
    }
    return \%categories;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::CommandFactory - Responsible for installing all commands

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
