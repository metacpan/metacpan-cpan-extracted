#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Search the configuration of an application

package App::Cme::Command::search ;
$App::Cme::Command::search::VERSION = '1.034';
use strict;
use warnings;
use 5.10.1;

use App::Cme -command ;

use base qw/App::Cme::Common/;

use Config::Model::ObjTreeScanner;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->check_unknown_args($args);
    $self->process_args($opt,$args);
    return;
}

sub opt_spec {
    my ( $class, $app ) = @_;
    return (
        [
            "search=s"        => "string or pattern to search in configuration" ,
            { required => 1 }
        ],
        [
            "narrow-search=s" => "narrows down the search to element, value, key, summary, description or help",
            { regex => qr/^(?:element|value|key|summary|description|help|all)$/, default => 'all' }
        ],
        $class->cme_global_options,
    );
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [application]  [ config_file ] -search xxx [ -narrow-search ... ] " ;
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my ($model, $inst, $root) = $self->init_cme($opt,$args);

    my @res = $root->tree_searcher( type => $opt->{narrow_search} )->search($opt->{search});
    foreach my $path (@res) {
        print "$path";
        my $obj = $root->grab($path);
        if ( $obj->get_type =~ /leaf|check_list/ ) {
            my $v = $obj->fetch;
            $v = defined $v ? $v : '<undef>';
            print " -> '$v'";
        }
        print "\n";
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::search - Search the configuration of an application

=head1 VERSION

version 1.034

=head1 SYNOPSIS

=head1 DESCRIPTION

Search configuration data with the following options:

=over

=item -search

Specifies a string or pattern to search. C<cme> will a list of path pointing
to the matching tree element and their value.
See L<Config::Model::AnyThing/grab(...)> for details
on the path syntax.

=item -narrow-search

Narrows down the search to:

=over

=item element

=item value

=item key

=item summary

Summary text

=item description

description text

=item help

value help text

=back

=back

Example:

 $ cme search multistrap my_mstrap.conf -search http -narrow value
 sections:base source -> 'http://ftp.fr.debian.org'
 sections:debian source -> 'http://ftp.uk.debian.org/debian'
 sections:toolchains source -> 'http://www.emdebian.org/debian'

=head1 Common options

See L<cme/"Global Options">.

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
