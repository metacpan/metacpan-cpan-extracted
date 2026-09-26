#
#  This file is part of ASPEER::MakeMaker::Markdown::Publish.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package ASPEER::MakeMaker::Markdown::Publish::MM;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION @ISA);
use warnings;


#  Shared MakeMaker implementation and configuration
#
use ASPEER::MakeMaker::MM ();
use ASPEER::MakeMaker::MM::Import ();
use ASPEER::MakeMaker::MM::Util;
use ASPEER::MakeMaker::Markdown::Publish::MM::Constant ();
@ISA=qw(ASPEER::MakeMaker::MM);


#  Configuration serialization stays inside the MakeMaker layer
#
use JSON::PP qw(decode_json encode_json);
use MIME::Base64 qw(decode_base64 encode_base64);


#  Version information
#
$VERSION='1.003';


#  Done
#
1;


#======================================================================================================================

sub const_config {


    #  Retain the common MakeMaker behavior before adding this plugin's live
    #  x_documentation configuration to its private macro namespace.
    #
    my ($self, $mm_or, @param)=@_;
    my $const_config=ASPEER::MakeMaker::MM::Import::const_config(
        $self,
        $mm_or,
        @param
    );
    my $meta_hr=$mm_or->{'META_MERGE'} || {};
    my $documentation_hr=$meta_hr->{'x_documentation'};
    if (defined($documentation_hr) && ref($documentation_hr) ne 'HASH') {
        die "META_MERGE.x_documentation must be a hash reference\n";
    }
    $documentation_hr={} unless defined($documentation_hr);
    my $publish_hr=$documentation_hr->{'publish'};
    if (defined($publish_hr) && ref($publish_hr) ne 'HASH') {
        die "META_MERGE.x_documentation.publish must be a hash reference\n";
    }
    $publish_hr={} unless defined($publish_hr);
    $mm_or->{'macro'}{'PUBLISH_CONFIG'}=encode_base64(encode_json($publish_hr), '');
    return $const_config;

}


sub publish {


    #  Decode the Makefile-safe metadata payload and delegate the requested
    #  action without re-running Makefile.PL.
    #
    my ($self, $param_hr)=(shift(), arg(@_));
    my ($encoded, $action)=@{$param_hr->{'ARGV_AR'}};
    die "publication configuration unavailable\n"
        unless defined($encoded) && length($encoded);
    my $publish_hr=decode_json(decode_base64($encoded));
    die "publication configuration must decode to a hash reference\n"
        unless ref($publish_hr) eq 'HASH';
    if (!exists($publish_hr->{'name'}) &&
        !exists($publish_hr->{'config_file'}) &&
        defined($param_hr->{'NAME'}) && length($param_hr->{'NAME'})) {
        $publish_hr->{'name'}=$param_hr->{'NAME'};
    }
    require Markdown::Publish;
    my $publish_or=Markdown::Publish->new($publish_hr);
    return $publish_or->run($action);

}

__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Publish::MM - generated publication target dispatcher

# DESCRIPTION

This class implements the MakeMaker-specific portion of
`ASPEER::MakeMaker::Markdown::Publish`. It inherits the common MakeMaker helper,
encodes `META_MERGE.x_documentation.publish` into a private Makefile macro, and
delegates generated targets to `Markdown::Publish`.

# METHODS

## const_config

Calls the shared `ASPEER::MakeMaker` `const_config` implementation, validates
the `x_documentation` metadata shape, and stores the JSON publication hash as a
Makefile-safe Base64 value.

## publish

Decodes the configuration passed by the generated target. When inline
configuration does not contain `name`, it uses the MakeMaker `NAME` as the
default site title. An external `config_file` remains authoritative. The method
then constructs `Markdown::Publish` and invokes the requested action on
the selected backend class.

# SEE ALSO

`ASPEER::MakeMaker::Markdown::Publish`, `Markdown::Publish`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Publish.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

ASPEER::MakeMaker::Markdown::Publish::MM - generated publication target dispatcher


=head1 DESCRIPTION

This class implements the MakeMaker-specific portion of
C<ASPEER::MakeMaker::Markdown::Publish>. It inherits the common MakeMaker helper,
encodes C<META_MERGE.x_documentation.publish> into a private Makefile macro, and
delegates generated targets to C<Markdown::Publish>.


=head1 METHODS


=head2 const_config

Calls the shared C<ASPEER::MakeMaker> C<const_config> implementation, validates
the C<x_documentation> metadata shape, and stores the JSON publication hash as a
Makefile-safe Base64 value.


=head2 publish

Decodes the configuration passed by the generated target. When inline
configuration does not contain C<name>, it uses the MakeMaker C<NAME> as the
default site title. An external C<config_file> remains authoritative. The method
then constructs C<Markdown::Publish> and invokes the requested action on
the selected backend class.


=head1 SEE ALSO

C<ASPEER::MakeMaker::Markdown::Publish>, C<Markdown::Publish>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
