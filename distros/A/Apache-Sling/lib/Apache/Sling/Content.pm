#!/usr/bin/perl -w

package Apache::Sling::Content;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Apache::Sling;
use Apache::Sling::ContentUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = qw(command_line);

our $VERSION = '0.27';

#{{{sub new
sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $content = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $content, $class;
    return $content;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $content, $message, $response ) = @_;
    $content->{'Message'}  = $message;
    $content->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $content, $remote_dest, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::add_setup(
            $content->{'BaseURL'}, $remote_dest, $properties
        )
    );
    my $success = Apache::Sling::ContentUtil::add_eval($res);
    my $message = "Content addition to \"$remote_dest\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $content, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $content->config( $sling, @ARGV );
    return $content->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $content, $sling, @ARGV ) = @_;
    my $content_config = $content->config_hash( $sling, @ARGV );

    GetOptions(
        $content_config,    'auth=s',
        'help|?',            'log|L=s',
        'man|M',             'pass|p=s',
        'threads|t=s',       'url|U=s',
        'user|u=s',          'verbose|v+',
        'add|a',             'additions|A=s',
        'copy|c',            'delete|d',
        'exists|e',          'filename|n=s',
        'local|l=s',         'move|m',
        'property|P=s',      'remote|r=s',
        'remote-source|S=s', 'replace|R',
        'view|V'
    ) or $content->help();

    return $content_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $content, $sling, @ARGV ) = @_;
    my $add;
    my $additions;
    my $copy;
    my $delete;
    my $exists;
    my $filename;
    my $local;
    my $move;
    my @property;
    my $remote;
    my $remote_source;
    my $replace;
    my $view;

    my %content_config = (
        'auth'          => \$sling->{'Auth'},
        'help'          => \$sling->{'Help'},
        'log'           => \$sling->{'Log'},
        'man'           => \$sling->{'Man'},
        'pass'          => \$sling->{'Pass'},
        'threads'       => \$sling->{'Threads'},
        'url'           => \$sling->{'URL'},
        'user'          => \$sling->{'User'},
        'verbose'       => \$sling->{'Verbose'},
        'add'           => \$add,
        'additions'     => \$additions,
        'copy'          => \$copy,
        'delete'        => \$delete,
        'exists'        => \$exists,
        'filename'      => \$filename,
        'local'         => \$local,
        'move'          => \$move,
        'property'      => \@property,
        'remote'        => \$remote,
        'remote-source' => \$remote_source,
        'replace'       => \$replace,
        'view'          => \$view
    );

    return \%content_config;
}

#}}}

#{{{sub copy
sub copy {
    my ( $content, $remote_src, $remote_dest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::copy_setup(
            $content->{'BaseURL'}, $remote_src, $remote_dest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::copy_eval($res);
    my $message = "Content copy from \"$remote_src\" to \"$remote_dest\" ";
    $message .= ( $success ? 'completed!' : 'did not complete successfully!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = "Content \"$remote_dest\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub del
sub del {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::delete_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::delete_eval($res);
    my $message = "Content \"$remote_dest\" ";
    $message .= ( $success ? 'deleted!' : 'was not deleted!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --additions or -A (file)          - File containing list of content to be uploaded.
 --add or -a                       - Add content.
 --auth (type)                     - Specify auth type. If ommitted, default is used.
 --copy or -c                      - Copy content.
 --delete or -d                    - Delete content.
 --filename or -n (filename)       - Specify file name to use for content upload.
 --help or -?                      - view the script synopsis and options.
 --local or -l (localPath)         - Local path to content to upload.
 --log or -L (log)                 - Log script output to specified log file.
 --man or -M                       - view the full script documentation.
 --move or -m                      - Move content.
 --pass or -p (password)           - Password of user performing content manipulations.
 --property or -P (property)       - Specify property to set on node.
 --remote or -r (remoteNode)       - specify remote destination under JCR root to act on.
 --remote-source or -S (remoteSrc) - specify remote source node under JCR root to act on.
 --replace or -R                   - when copying or moving, overwrite remote destination if it exists.
 --threads or -t (threads)         - Used with -A, defines number of parallel
                                     processes to have running through file.
 --url or -U (URL)                 - URL for system being tested against.
 --user or -u (username)           - Name of user to perform content manipulations as.
 --verbose or -v or -vv or -vvv    - Increase verbosity of output.
 --view or -V (actOnGroup)         - view details for specified group in json format.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {
    my ($content) = @_;

    print <<'EOF';
content perl script. Provides a means of uploading content into sling from the
command line. The script also acts as a reference implementation for the
Content perl library.

EOF

    $content->help();

    print <<"EOF";
Example Usage

* Authenticate and add a node at /test:

 perl $0 -U http://localhost:8080 -a -r /test -u admin -p admin

* Authenticate and add a node at /test with property p1 set to v1:

 perl $0 -U http://localhost:8080 -a -r /test -P p1=v1 -u admin -p admin

* Authenticate and add a node at /test with property p1 set to v1, and p2 set to v2:

 perl $0 -U http://localhost:8080 -a -r /test -P p1=v1 -P p2=v2 -u admin -p admin

* View json for node at /test:

 perl $0 -U http://localhost:8080 -V -r /test

* Check whether node at /test exists:

 perl $0 -U http://localhost:8080 -V -r /test

* Authenticate and copy content at /test to /test2

 perl $0 -U http://localhost:8080 -c -S /test -r /test2 -u admin -p admin

* Authenticate and move content at /test to /test2, replacing test2 if it already exists

 perl $0 -U http://localhost:8080 -m -S /test -r /test2 -R -u admin -p admin

* Authenticate and delete content at /test

 perl $0 -U http://localhost:8080 -d -r /test -u admin -p admin
EOF

    return 1;
}

#}}}

#{{{sub move
sub move {
    my ( $content, $remote_src, $remote_dest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::move_setup(
            $content->{'BaseURL'}, $remote_src, $remote_dest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::move_eval($res);
    my $message = "Content move from \"$remote_src\" to \"$remote_dest\" ";
    $message .= ( $success ? 'completed!' : 'did not complete successfully!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub run
sub run {
    my ( $content, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No content config supplied!';
    }
    $sling->check_forks;
    ${ $config->{'remote'} } =
      Apache::Sling::URL::strip_leading_slash( ${ $config->{'remote'} } );
    ${ $config->{'remote-source'} } = Apache::Sling::URL::strip_leading_slash(
        ${ $config->{'remote-source'} } );
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : Apache::Sling::Authn->new( \$sling );
    my $success = 1;

    if ( $sling->{'Help'} ) { $content->help(); }
    elsif ( $sling->{'Man'} )  { $content->man(); }
    elsif ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding content from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent( $sling->{'Referer'} );
                $authn->login_user();
                my $content =
                  Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $content->upload_from_file( ${ $config->{'additions'} },
                    $i, $sling->{'Threads'} );
                exit 0;
            }
            else {
                croak "Could not fork $i!";
            }
        }
        foreach (@childs) { waitpid $_, 0; }
    }
    else {
        $authn->login_user();
        if (   defined ${ $config->{'local'} }
            && defined ${ $config->{'remote'} } )
        {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->upload_file(
                ${ $config->{'local'} },
                ${ $config->{'remote'} },
                ${ $config->{'filename'} }
            );
        }
        elsif ( defined ${ $config->{'exists'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->check_exists( ${ $config->{'remote'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success =
              $content->add( ${ $config->{'remote'} }, $config->{'property'} );
        }
        elsif ( defined ${ $config->{'copy'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->copy(
                ${ $config->{'remote-source'} },
                ${ $config->{'remote'} },
                ${ $config->{'replace'} }
            );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->del( ${ $config->{'remote'} } );
        }
        elsif ( defined ${ $config->{'move'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->move(
                ${ $config->{'remote-source'} },
                ${ $config->{'remote'} },
                ${ $config->{'replace'} }
            );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $content =
              Apache::Sling::Content->new( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $content->view( ${ $config->{'remote'} } );
        }
        else {
            $content->help();
            return 1;
        }
        Apache::Sling::Print::print_result($content);
    }
    return $success;
}

#}}}

#{{{sub upload_file
sub upload_file {
    my ( $content, $local_path, $remote_path, $filename ) = @_;
    $filename = defined $filename ? $filename : q{};
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::upload_file_setup(
            $content->{'BaseURL'}, $local_path, $remote_path, $filename
        )
    );
    my $success  = Apache::Sling::ContentUtil::upload_file_eval($res);
    my $basename = $local_path;
    $basename =~ s/^(.*\/)([^\/]*)$/$2/msx;
    my $remote_dest =
      $remote_path . ( $filename ne q{} ? "/$filename" : "/$basename" );
    my $message = "Content: \"$local_path\" upload to \"$remote_dest\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub upload_from_file
sub upload_from_file {
    my ( $content, $file, $fork_id, $number_of_forks ) = @_;
    $fork_id         = defined $fork_id         ? $fork_id         : 0;
    $number_of_forks = defined $number_of_forks ? $number_of_forks : 1;
    my $count = 0;
    if ( !defined $file ) {
        croak 'File to upload from not defined';
    }
    if ( open my ($input), '<', $file ) {
        while (<$input>) {
            if ( $fork_id == ( $count++ % $number_of_forks ) ) {
                chomp;
                $_ =~ /^(\S.*?),(\S.*?)$/msx
                  or croak 'Problem parsing content to add';
                my $local_path  = $1;
                my $remote_path = $2;
                $content->upload_file( $local_path, $remote_path, q{} );
                Apache::Sling::Print::print_result($content);
            }
        }
        close $input or croak 'Problem closing input!';
    }
    else {
        croak "Problem opening file: '$file'";
    }
    return 1;
}

#}}}

#{{{sub view
sub view {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing content: \"$remote_dest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view_file
sub view_file {
    my ( $content, $remote_dest ) = @_;
    if ( !defined $remote_dest ) {
        croak 'No file to view specified!';
    }
    my $res = Apache::Sling::Request::request( \$content,
        "get $content->{ 'BaseURL' }/$remote_dest" );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing content: \"$remote_dest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view_full_json
sub view_full_json {
    my ( $content, $remote_dest ) = @_;
    if ( !defined $remote_dest ) {
        croak 'No file to view specified!';
    }
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::full_json_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::full_json_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing json: \"$remote_dest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::Content - Manipulate Content in an Apache SLing instance.

=head1 ABSTRACT

content related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a Content object.

=head2 set_results

Set a suitable message and response for the content object.

=head2 add

Add new content to the system.

=head2 copy

Copy content in the system.

=head2 config

Fetch hash of content configuration.

=head2 check_exists

Check whether content exists.

=head2 del

Delete content.

=head2 move

Move location of content in the system.

=head2 run

Run content related actions.

=head2 upload_file

Upload a file into the system.

=head2 upload_from_file

Upload new content to the system based on definitions in a file.

=head2 view

View content details.

=head2 view_file

View content.

=head2 view_full_json

View JSON representation of content.

=head1 USAGE

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST content methods

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
