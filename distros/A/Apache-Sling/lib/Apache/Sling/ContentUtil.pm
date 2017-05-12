#!/usr/bin/perl -w

package Apache::Sling::ContentUtil;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub add_setup

sub add_setup {
    my ( $base_url, $remote_dest, $properties ) = @_;
    if ( !defined $base_url ) { croak 'No base URL provided!'; }
    if ( !defined $remote_dest ) {
        croak 'No position or ID to perform action for specified!';
    }
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables = "\$post_variables = [$property_post_vars]";
    return "post $base_url/$remote_dest $post_variables";
}

#}}}

#{{{sub add_eval

sub add_eval {
    my ($res) = @_;
    return ( ${$res}->code =~ /^20(0|1)$/msx );
}

#}}}

#{{{sub copy_setup

sub copy_setup {
    my ( $base_url, $remote_src, $remote_dest, $replace ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $remote_src ) {
        croak 'No content source to copy from defined!';
    }
    if ( !defined $remote_dest ) {
        croak 'No content destination to copy to defined!';
    }
    my $post_variables =
      "\$post_variables = [':dest','$remote_dest',':operation','copy'";
    $post_variables .= ( defined $replace ? q{,':replace','true'} : q{} );
    $post_variables .= ']';
    return "post $base_url/$remote_src $post_variables";
}

#}}}

#{{{sub copy_eval

sub copy_eval {
    my ($res) = @_;
    return ( ${$res}->code =~ /^20(0|1)$/msx );
}

#}}}

#{{{sub delete_setup

sub delete_setup {
    my ( $base_url, $remote_dest ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $remote_dest ) {
        croak 'No content destination to delete defined!';
    }
    my $post_variables = q{$post_variables = [':operation','delete']};
    return "post $base_url/$remote_dest $post_variables";
}

#}}}

#{{{sub delete_eval

sub delete_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub exists_setup

sub exists_setup {
    my ( $base_url, $remote_dest ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $remote_dest ) {
        croak 'No position or ID to perform exists for specified!';
    }
    return "get $base_url/$remote_dest.json";
}

#}}}

#{{{sub exists_eval

sub exists_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub full_json_setup

sub full_json_setup {
    my ( $base_url, $remote_dest ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $remote_dest ) {
        croak 'No position or ID to retrieve full json for specified!';
    }
    return "get $base_url/$remote_dest.infinity.json";
}

#}}}

#{{{sub full_json_eval

sub full_json_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub move_setup

sub move_setup {
    my ( $base_url, $remote_src, $remote_dest, $replace ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $remote_src ) {
        croak 'No content source to move from defined!';
    }
    if ( !defined $remote_dest ) {
        croak 'No content destination to move to defined!';
    }
    my $post_variables =
      "\$post_variables = [':dest','$remote_dest',':operation','move'";
    $post_variables .= ( defined $replace ? q{,':replace','true'} : q{} );
    $post_variables .= ']';
    return "post $base_url/$remote_src $post_variables";
}

#}}}

#{{{sub move_eval

sub move_eval {
    my ($res) = @_;
    return ( ${$res}->code =~ /^20(0|1)$/msx );
}

#}}}

#{{{sub upload_file_setup

sub upload_file_setup {
    my ( $base_url, $local_path, $remote_dest, $filename ) = @_;
    if ( !defined $base_url ) {
        croak 'No base URL provided to upload against!';
    }
    if ( !defined $local_path ) { croak 'No local file to upload defined!'; }
    if ( !defined $remote_dest ) {
        croak "No remote path to upload to defined for file $local_path!";
    }
    if ( $filename eq q{} ) { $filename = './*'; }
    my $post_variables = '$post_variables = []';
    return
      "fileupload $base_url/$remote_dest $filename $local_path $post_variables";
}

#}}}

#{{{sub upload_file_eval

sub upload_file_eval {
    my ($res) = @_;
    return ( ${$res}->code =~ /^20(0|1)$/msx );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::ContentUtil - Methods to generate and check HTTP requests required for manipulating content.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
content operations in the system.

=head1 METHODS

=head1 USAGE

use Apache::Sling::ContentUtil;

=head1 DESCRIPTION

ContentUtil perl library essentially provides the request strings needed to
interact with content functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=head1 METHODS

=head2 add_setup

Returns a textual representation of the request needed to add content to the
system.

=head2 add_eval

Check result of adding content.

=head2 copy_setup

Returns a textual representation of the request needed to copy content within
the system.

=head2 copy_eval

Inspects the result returned from issuing the request generated in copy_setup
returning true if the result indicates the content was copied successfully,
else false.

=head2 delete_setup

Returns a textual representation of the request needed to delete content from
the system.

=head2 delete_eval

Inspects the result returned from issuing the request generated in delete_setup
returning true if the result indicates the content was deleted successfully,
else false.

=head2 exists_setup

Returns a textual representation of the request needed to test whether content
exists in the system.

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the content does exist in the system,
else false.

=head2 full_json_setup

Returns a textual representation of the request needed to retrieve the full JSON
representation of a piece of content in the system.

=head2 full_json_eval

Inspects the result returned from issuing the request generated in
full_json_setup returning true if the result indicates the full JSON
representation was returned successfully else false.

=head2 move_setup

Returns a textual representation of the request needed to move content within
the system.

=head2 move_eval

Inspects the result returned from issuing the request generated in move_setup
returning true if the result indicates the content was moved successfully,
else false.

=head2 upload_file_setup

Returns a textual representation of the request needed to upload a file to the system.

=head2 upload_file_eval

Check result of system upload_file.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
