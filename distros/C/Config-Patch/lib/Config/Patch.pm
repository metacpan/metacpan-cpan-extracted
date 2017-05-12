##################################################
package Config::Patcher::Util;
##################################################

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

###########################################
package Config::Patch::Hunk;
###########################################
use MIME::Base64;

our @accessors = qw(
  mode key text pos_from pos_to header
  content_pos_from content_pos_to regex method
  as_string
);
Config::Patcher::Util::make_accessor( __PACKAGE__, $_ ) for @accessors;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        comment_char => '#',
        mode         => "append",
        key          => undef,
        text         => undef,
        %options,
    };

    bless $self, $class;
}

###########################################
sub patch_marker {
###########################################
    my($self) = @_;

    return $self->{comment_char} .
           "(Config::Patch-" .
           "$self->{key}-" .
           $self->mode() .
           ")" .
           "\n";
}

###########################################
sub string_generate {
###########################################
    my($self) = @_;

    return $self->patch_marker() . 
           $self->text() .
           $self->patch_marker();
}

###########################################
sub freeze {
###########################################
    my($self, $string) = @_;

    # Hide an arbitrary string in a comment
    my $encoded = encode_base64($string);

    $encoded =~ s/^/$self->{comment_char} /gm;
    return $encoded;
}

###########################################
sub thaw {
###########################################
    my($self, $string) = @_;

    # Decode a hidden string 
    $string =~ s/^$self->{comment_char} //gm;
    my $decoded = decode_base64($string);
    return $decoded;
}

###########################################
sub replstring_extract {
###########################################
    my($self) = @_;

    my $text = $self->text();

    # Find the replace string in a patch
    my $replace_marker = $self->replace_marker();
    $replace_marker = quotemeta($replace_marker);
    if($text =~ /^$replace_marker\n(.*?)
                  ^$replace_marker/xms) {
        my $repl = $1;
        $text =~ s/^$replace_marker.*?
                    ^$replace_marker\n//xms;

        return($self->thaw($repl), $text);
    }

    return undef;
}

###########################################
sub replstring_hide {
###########################################
    my($self, $replstring) = @_;

    # Add a replace string to a patch
    my $replace_marker = $self->replace_marker();
    my $encoded = $replace_marker . "\n" .
                  $self->freeze($replstring) .
                  $replace_marker .
                  "\n";

    return $encoded;
}

###########################################
sub replace_marker {
###########################################
    my($self) = @_;

    return $self->{comment_char} .
           "(Config::Patch::replace)";
}

###########################################
package Config::Patch;
###########################################
use strict;
use warnings;
use Set::IntSpan;
use Fcntl qw(:flock);
use Log::Log4perl qw(:easy);

our $VERSION     = "0.09";

our @accessors = qw(data file comment_char key);
Config::Patcher::Util::make_accessor( __PACKAGE__, $_ ) for @accessors;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        comment_char => '#',
        key          => undef,
        file         => undef,
        parsed       => 0,
        read         => 0,
        %options,
    };

    my $package = __PACKAGE__;

    $self->{patch_regex} = 
        qr{^$self->{comment_char}\($package-(.*)-(.*?)\)}m;

    bless $self, $class;
}

###########################################
sub read {
###########################################
    my($self, $file) = @_;

    if(defined $file) {
        $self->{file} = $file;
    }

    $self->{data} = $self->slurp( $self->{file} );

      # fix trailing newline if it's missing
    $self->{data} .= "\n" unless substr($self->{data}, -1, 1) eq "\n";

    $self->{parsed} = 0;
    $self->{read}   = 1;

    return $self->{data};
}

###########################################
sub error {
###########################################
    my($self, @text) = @_;

    if(defined $text[0]) {
        $self->{error} = join "", @text;
        ERROR $self->{error};
    }

    return $self->{error};
}

###########################################
sub patch_by_stretch {
###########################################
    my($self, $text, $mode) = @_;

    LOGDIE "No key defined" unless 
        defined $self->{key};

    LOGDIE "No mode defined" unless 
        defined $mode;

    my $patch = Config::Patch::Hunk->new(
        comment_char => $self->{comment_char},
        key          => $self->{key},
        text         => $text,
        mode         => $mode,
    );

    return $self->apply( $patch );
}

###########################################
sub apply {
###########################################
    my($self, $patch) = @_;

    $self->read() unless $self->{read};

    $patch->{comment_char} = $self->{comment_char};

    my $key = $patch->key();

      # TODO: Lower-level functions expect it there, but probably should
      # be carried as an argument.
    $self->{key} = $key;

    my $patchtext = $patch->string_generate();
    
    if ($patch->{mode} eq "prepend") {
        $self->{data} = $patchtext . $self->{data};

    } elsif ($patch->{mode} eq "append") {
        $self->{data} .= $patchtext;

    } elsif ($patch->{mode} eq "replace") {
        $self->patch_by_wedge($patch->regex(), $patch->text(), "replace");

    } elsif ($patch->{mode} eq "insert-before") {
        $self->patch_by_wedge($patch->regex(), $patch->text(), "insert");

    } elsif ($patch->{mode} eq "insert-after") {
        $self->patch_by_wedge($patch->regex(), $patch->text(), "insert", 1);

    } elsif ($patch->{mode} eq "update") {
        $self->patch_update( $patch->key(), $patch->text() );

    } elsif ($patch->{mode} eq "comment_out") {
        $self->patch_comment_out( $patch->key(), $patch->regex() );

    } else {
        LOGDIE "Unknown mode '$patch->{mode}'";
    }

    return 1;
}

###########################################
sub save {
###########################################
    my($self) = @_;

    $self->blurt($self->{data}, $self->{file});
}

###########################################
sub save_as {
###########################################
    my($self, $file) = @_;

    LOGDIE "No file defined" unless defined $file;
    $self->{file} = $file;

    return $self->save();
}

###########################################
sub patched {
###########################################
    my($self, $key) = @_;

    my @patches = $self->parse();

    if( grep { $key eq $_->key() } @patches ) {
        return 1;
    }

    return 0;
}

###########################################
sub parse {
###########################################
    my($self) = @_;

    my @patches = ();

    $self->{forbidden_zones} = Set::IntSpan->new();

    $self->data_traverse( sub { 
        my($patcher, $patch) = @_;

        $patcher->{forbidden_zones} = 
          Set::IntSpan::union( $patcher->{forbidden_zones}, 
            ($patch->pos_from() . "-" . $patch->pos_to()));

        push @patches, $patch;
    }, sub {
    });

    $self->{parsed} = 1;

    return @patches;
}

###########################################
sub patch_update {
###########################################
    my($self, $key, $newvalue) = @_;

    if(length $newvalue and
       substr($newvalue, -1, 1) ne "\n") {
        $newvalue .= "\n";
    }

    my $skew = 0;

    for my $hunk ( $self->parse() ) {
        next if $hunk->key() ne $key;

        substr($self->{data}, $hunk->content_pos_from + $skew, 
               $hunk->content_pos_to - $hunk->content_pos_from) 
            = $newvalue;

        $skew += length($newvalue) - length($hunk->text());
    }
}

###########################################
sub patches_only {
###########################################
    my($self) = @_;

    my $new_content = "";

    for my $hunk ( $self->parse() ) {
        $new_content .= $hunk->as_string();
    }

    $self->{data} = $new_content;
}

###########################################
sub patch_by_wedge {
###########################################
    my($self, $search, $replace, $mode, $after) = @_;

    if($self->patched( $self->{key} )) {
        INFO "$mode cancelled: File already patched with key $self->{key}";
        return undef;
    }

    if(ref($search) ne "Regexp") {
        LOGDIE "$mode search parameter not a regex {$search}";
    }

    if(length $replace and
       substr($replace, -1, 1) ne "\n") {
        $replace .= "\n";
    }

    my $data = $self->{data};

    my $positions = $self->full_line_match($data, $search);
    my @pieces    = ();
    my $rest      = $data;
    my $offset    = 0;

    my $patch = Config::Patch::Hunk->new(
        comment_char => $self->{comment_char},
        key          => $self->{key},
        mode         => $mode,
    );

    for my $pos (@$positions) {
        my($from, $to) = @$pos;
        my($before, $trail);
        my $hide;
        if ($mode eq "insert" ) {
            if ($after) {
                $before = substr($data, $offset, $to+1);
                $rest   = substr($data, $to+1);
                $hide   = "";
                $trail  = "";
            } else {
                $before = substr($data, $offset, $from-$offset);
                $rest   = substr($data, $to+1);
                $hide   = "";
                $trail  = substr($data, $from, $to - $from + 1);
            }
        } elsif ($mode eq "replace") {
            $before = substr($data, $offset, $from-$offset);
            $rest   = substr($data, $to+1);

            $hide   = $patch->replstring_hide(
                        substr($data, $from, $to - $from + 1));
            $trail  = "";
        }

        $patch->text( $replace . $hide );
        push @pieces, $before, $patch->string_generate(), $trail;
        $offset = $to + 1;
    }

    push @pieces, $rest;

    $self->{data} = join '', @pieces;

    return 1;
}

###########################################
sub full_line_match {
###########################################
    my($self, $string, $rex) = @_;

    DEBUG "Trying to match '$string' with /$rex/";

    # Try a regex match and if it succeeds, extend the match
    # to cover the full first and last line. Return a ref to
    # an array of from-to offsets of all (extended) matching
    # regions.
    my @positions = ();

    while($string =~ /($rex)/g) {
        my $first = pos($string) - length($1);
        my $last  = pos($string) - 1;

        DEBUG "Found match at pos $first-$last ($1) pos=", pos($string);

            # Is this match located in any of the forbidden zones?
        my $intersect = Set::IntSpan::intersect(
                            $self->{forbidden_zones}, "$first-$last");
        unless(Set::IntSpan::empty($intersect)) {
            DEBUG "Match was in forbidden zone - skipped";
            next;
        }

            # Go back to the start of the line
        while($first and
              substr($string, $first, 1) ne "\n") {
            $first--;
        }
        $first += 1 if $first;

            # Proceed until the end of the line
        while($last < length($string) and
              substr($string, $last, 1) ne "\n") {
            $last++;
        }

        DEBUG "Match positions corrected to $first-$last (line start/end)";

            # Ignore overlapping matches
        if(@positions and $positions[-1]->[1] > $first) {
            DEBUG "Detected overlap (two matches in same line) - skipped";
            next;
        }

        push @positions, [$first, $last];
    }

    return \@positions;
}

###########################################
sub comment_out {
###########################################
    my($self, $search) = @_;

        # Same as "replace by nothing"
    return $self->replace($search, "");
}

###########################################
sub eject {
###########################################
    my($self, $key) = @_;

    $self->read() unless $self->{read};

      # We accept a hunk instead of a key as well
    if(ref $key eq __PACKAGE__ . "::Hunk") {
        $key = $key->key();
    }

    $key = $self->{key} unless defined $key;

    my $new_content = "";

    $self->data_traverse( sub { 
        my($patcher, $patch) = @_;

        DEBUG "Remove: '", $patch->text(), "' (",
              $patch->pos_from(), "-", $patch->pos_to();

        if($patch->key() eq $key) {
            if($patch->mode() eq "replace") {
                  # We've got a replace section, extract its
                  # hidden content and re-establish it
                my($hidden, $stripped) = $patch->replstring_extract();
                $new_content .= $hidden;
            } else {
                # Replace by nothing
            }
        } else {
                # This isn't our patch
            $new_content .= $patch->header() . 
                            $patch->text() .
                            $patch->header();
        }
    }, sub {
        my($patcher, $text) = @_;
        $new_content .= $text;
    });

    $self->{data} = $new_content;
}

###########################################
sub data_traverse {
###########################################
    my($self, $patch_cb, $text_cb) = @_;

    my $in_patch  = 0;
    my $patch_text     = "";
    my $text      = "";
    my $start_pos;
    my $end_pos;
    my $pos       = 0;
    my $header;

    for my $line (split /\n/, $self->{data}) {
        $_ = "$line\n";

        $pos += length($_);
        $patch_text .= $_ if $in_patch and $_ !~ $self->{patch_regex};

            # text line?
        if($_ !~ $self->{patch_regex} and !$in_patch) {
            $text .= $_;
        }

            # closing line of patch
        if($_ =~ $self->{patch_regex} and 
           $in_patch) {
            $end_pos = $pos - 1;

            my $patch_obj = Config::Patch::Hunk->new(
                comment_char      => $self->{comment_char},
                key               => $1,
                mode              => $2,
                text              => $patch_text,
                pos_from          => $start_pos,
                pos_to            => $end_pos, 
                header            => $header,
                content_pos_from  => $start_pos + length($&) + 1,
                content_pos_to    => $end_pos   - length($&),
                as_string         => substr( $self->{data}, $start_pos,
                                             $end_pos - $start_pos + 1 ),
            );

            $patch_cb->($self, $patch_obj);
            $patch_text = "";
        }

            # toggle flag
        if($_ =~ $self->{patch_regex}) {
            if($in_patch) {
                # End line
            } else {
                # Start Line
                $text_cb->($self, $text);
                $start_pos = $pos - length $_;
                $header = $_;
            }
            $text = "";
            $in_patch = ($in_patch xor 1);
        }
    }

    $text_cb->($self, $text) if length $text;

    return 1;
}

###############################################
sub blurt {
###############################################
    my($self, $data, $file) = @_;

    open FILE, ">$file" or LOGDIE "Cannot open $file ($!)";
    print FILE $data;
    close FILE;
}

###############################################
sub slurp {
###############################################
    my($self, $file) = @_;

    local $/ = undef;
    open FILE, "<$file" or LOGDIE "Cannot open $file ($!)";
    my $data = <FILE>;
    close FILE;

    return $data;
}

###########################################
sub lock {
###########################################
    my($self) = @_;

        # Ignore if locking wasn't requested
    return if ! $self->{flock};

        # Already locked?
    if($self->{locked}) {
        $self->{locked}++;
        return 1;
    }

    open my $fh, "+<$self->{file}" or 
        LOGDIE "Cannot open $self->{file} ($!)";

    flock($fh, LOCK_EX);

    $self->{fh} = $fh;

    $self->{locked} = 1;
}

###########################################
sub unlock {
###########################################
    my($self) = @_;

        # Ignore if locking wasn't requested
    return if ! $self->{flock};

    if(! $self->{locked}) {
            # Not locked?
        return 1;
    }

    if($self->{locked} > 1) {
            # Multiple lock released?
        $self->{locked}--;
        return 1;
    }

        # Release the last lock
    flock($self->{fh}, LOCK_UN);
    $self->{locked} = undef;
    1;
}

# LEGACY METHODS

###########################################
sub patches {
###########################################
    my($self) = @_;

    # LEGACY METHOD, DON'T USE

    my @patches = ();
    my %patches = ();

    $self->data_traverse(
        sub { my($patcher, $patch) = @_;
              push @patches, 
                   [$patch->key(), 
                    $patch->mode(),
                    $patch->text(),
                    $patch->pos_from(),
                    $patch->pos_to(),
                    $patch->header(),
                    $patch->content_pos_from(),
                    $patch->content_pos_to(),
                   ];
              $patches{ $patch->key() }++;
            },
        sub { },
    );

    return \@patches, \%patches;
}

###########################################
sub prepend {
###########################################
    my($self, $text) = @_;

    # LEGACY METHOD, DON'T USE

    $self->lock();
    $self->read() unless $self->{read};

    $self->patch_by_stretch( $text, "prepend" );

    $self->save();
    $self->unlock();
    return 1;
}

###########################################
sub append {
###########################################
    my($self, $text) = @_;

    # LEGACY METHOD, DON'T USE

    $self->lock();
    $self->read() unless $self->{read};

    $self->patch_by_stretch( $text, "append" );

    $self->save();
    $self->unlock();
    return 1;
}

###########################################
sub replace {
###########################################
    my($self, $search, $patchtext) = @_;

    # LEGACY METHOD, DON'T USE

    $self->lock();
    $self->read() unless $self->{read};

    $self->patch_by_wedge($search, $patchtext, "replace");

    $self->save();
    $self->unlock();
}

###########################################
sub insert {
###########################################
    my($self, $search, $data, $after) = @_;

    # LEGACY METHOD, DON'T USE

    $self->lock();
    $self->read() unless $self->{read};

    $self->patch_by_wedge($search, $data, "insert", $after);

    $self->save();
    $self->unlock();
}

###########################################
sub remove {
###########################################
    my($self, $key) = @_;

    # LEGACY METHOD, DON'T USE

    $self->lock();
    $self->read() unless $self->{read};

    $self->eject( $key );

    $self->save();
    $self->unlock();
}

1;

__END__

=head1 NAME

Config::Patch - Patch configuration files and unpatch them later

=head1 SYNOPSIS

    my $patcher = Config::Patch->new( 
        file => "/etc/sudoers",
    );

      # Add a line at the end of /etc/sudoers and reset the file
      # to its original state later on.
    my $patch = Config::Patch::Hunk->new(
        key  => "myapp",
        mode => "append",
        text => "joeschmoe ALL= NOPASSWD:/etc/rc.d/init.d/myapp",
    );

    $patcher->apply( $patch );
    $patcher->save();

      # later on: Get /etc/sudoers back to its original state
    $patcher->eject( "myapp" );
    $patcher->save();

=head1 DESCRIPTION

Config::Patch provides an interface to modify configuration files
in a way so that the changes can be rolled back later on.
For example, let's say that an application wants to append the line

    joeschmoe ALL= NOPASSWD:/etc/rc.d/init.d/myapp

at the end of the /etc/sudoers file to allow user joeschmoe to start and 
stop the myapp application as root without having to type a password.

Normally, you'd have to do this by hand or via an installation script.
And later on, when myapp gets ejected from the system,
you'd have to remember to delete the line from /etc/sudoers as well.

Config::Patch provides an automated way to apply this 'patch' to the
configuration file and to detect and eject it later on. It does this
by placing special markers around the insertion, without having to refer
to any external meta data.

Note that a 'patch'
in this context is just a snippet of text that's to be applied somewhere
within the file (not to be confused with the diff-formatted text used 
by the C<patch> Unix utility).
Patches are line-based, C<Config::Patch> always adds/removes entire lines.

=head2 Command line usage

To facilitate its usage, C<Config::Patch> comes with a command line script
that performs all functions:

        # Append a patch
    echo "my patch text" | config-patch -a -k key -f textfile

        # Patch a file by search-and-replace
    echo "none:" | config-patch -s 'all:.*' -k key -f config_file

        # Comment out sections matched by a regular expression:
    config-patch -c '(?ms-xi:^all:.*?\n\n)' -k key -f config_file

        # Remove a previously applied patch
    config-patch -r -k key -f textfile

You can only patch a file I<once> with a given key. Note that a single
patch might result in multiple patched sections within a file 
if you're using the C<replace()> or C<comment_out()> methods.

To apply different patches to the same file, use different keys. They
can be can rolled back separately.

=head2 API usage

With Config::Patch, you run

    my $patcher = Config::Patch->new( 
        file => "/etc/sudoers",
    );

to create a patcher object and then define a patch that appends a line
to the end of the file:

    my $patch = Config::Patch::Hunk->new(
        key  => "myapp",
        mode => "append",
        text => "joeschmoe ALL= NOPASSWD:/etc/rc.d/init.d/myapp",
    );

After applying the patch and saving the changes back to the original file,
the patch will be in place:

    $patcher->apply( $patch );
    $patcher->save();

along with markers that allow
Config::Patch to identify the patch later on and update or eject it:

    /etc/sudoers
    *------------------------------------------------
    | ...
    | previous content
    | ...
    | #(Config::Patch-myapp-append)
    | joeschmoe ALL= NOPASSWD:/etc/rc.d/init.d/myapp
    | #(Config::Patch-myapp-append)
    *------------------------------------------------

The markers are commented out by '#' marks, and are hence ignored by the
application reading the configuration file. However, Config::Patch uses
them later on to identify and expunge the comments from the file.

To remove the patch from the file later on, call

    $patcher->eject( "myapp" );
    $patcher->save();

and the patcher will scrub the new patch from /etc/sudoers and reset the file
to its original state.

The C<save()> method will write back the file under the name of the currently
active file. The path to this file was either set in the Config::Patch
constructor with the C<file> parameter, or gets set later explicitly via the 
C<file($path)> accessor. If you want to save patched content under a 
different name, use

    $patcher->save_as("newfile.dat");

This will also modify the current file setting, which means that if
you use read() or save() later on, it will use the newly set name.

To peek at the manipulated output before (or after) it's been written, use
C<$patcher-E<gt>data()> which returns the current state of the patcher's
text data.

Patch hunks can be applied to a file in several ways, as specified in
the hunk's C<mode> field. C<append> adds the patch at the end of the
file, C<prepend> at the beginning, and C<replace> searches for a regular
expression within the file and then replaces it by the patch. For details
on application modes, see the Config::Patch::Hunk section below.

=head2 Methods

=over 4

=item C<new()>

Creates a new Config::Patch object. Takes an optional C<file> parameter to
specify the 'current' file Config::Patch operates on.

=item C<file()>

Accessor for the path to the current file. Supports read and write.

=item C<read()>

Read the current file into memory. Called automatically by apply() if
no data has been read into memory yet.

=item C<data()>

Return the text data Config::Patch is operating on.

=item C<save()>

Write back the data to the current file.

=item C<save_as( $file )>

Write back the data to a file named $file. Sets C<$file> as the current file.

=item C<apply( $patch )>

Applies a patch (a Config::Patch::Hunk object) to the data.

=item C<eject( $key )>

Removes a patch applied previously under the specified key $key. 
Instead of a key string,
it optionally takes a Config::Patch::Hunk object.

=item C<eject_all()>

Remove all patches from the data.

=item C<parse()>

Returns a list of all applied patches so far as Config::Patch::Hunk objects.

    for my $patch ( $patcher->parse() ) {
        print $patch->text();
    }

=item C<patched( $key )>

Checks if a patch with the given key was applied to the data already 
and returns a true value if so.

=back

=head2 Config::Patch::Hunk Objects

=over 4

=item C<key()>

Returns/sets the key under which the key will be applied. The key serves
to identify the hunk and to distinguish it from other hunks when 
identifying/updating/removing the hunk later.

=item C<mode()>

How the patch will be applied to the data. Supported modes are 

=over 4

=item C<append> 

Add the patch at the end of the data.

=item C<prepend>

Insert the patch at the beginning of the data.

=item C<replace>

Replace line ranges matching the regular expression in C<regex> with the
patch. Encode the replaced data and store it in the patch header, so that
it can be put back into place, when the patch is ejected later.

For example, to, replace the 'all:' target in a Makefile and all 
of its production rules by a dummy rule, use

    my $hunk = Config::Patch::Hunk->new(
        key  => "myapp",
        mode => "replace",
        regex => qr(^all:.*?\n\n)sm),
        text => "all:\n\techo 'all is gone!'\n",
    );

    $patcher->apply( $hunk );

to transform

    Makefile (before)
    *------------------------------------------------
    | all: 
    |     do-this-and-that
    *------------------------------------------------

into

    Makefile (after)
    *------------------------------------------------
    | #(Config::Patch-myapp-replace)
    | all:
    |     echo 'all is gone!'
    | #(Config::Patch::replace)
    | # YWxsOgoJZG8tdGhpcy1hbmQtdGhhdAoK
    | #(Config::Patch::replace)
    | #(Config::Patch-myapp-replace)
    *------------------------------------------------

Note the Base64 encoding which carries the original content of the 
replace line. To remove the patch, run

    $patcher->eject( "myapp" );
    $patcher->save();

and the original content of Makefile will be restored:

    Makefile (restored)
    *------------------------------------------------
    | all: 
    |     do-this-and-that
    *------------------------------------------------

Tip: To have a hunk comment out a section of the data without adding
anything to replace it, simply use an empty "text" field in "replace" mode.

=item C<insert-after>

Inserts the hunk after a line matching the regular expression defined
in C<rregex>.

        # Insert "foo=bar" into "[section]". 
    my $hunk = Config::Patch::Hunk->new(
        key   => "myapp",
        mode  => "insert-after",
        regex => qr(^\[section\])m,
        text  => "foo=bar", );

    $patcher->apply( $hunk );

transforms 

    [section]
    blah

into 

    [section]
    #(Config::Patch-myapp-insert)
    foo=bar
    #(Config::Patch-myapp-insert)
    blah

=item C<insert-before>

Inserts the hunk I<before> a line matching the regular expression defined
in C<$regex>.

        # Insert a new section before [section]
    my $hunk = Config::Patch::Hunk->new(
        key   => "myapp",
        mode  => "insert-before",
        regex => qr(^\[section\])m,
        text  => "[newsection]\nfoo=bar\n\n"
    );

    $patcher->apply( $hunk );

transforms

    [section]
    blah

into 

    #(Config::Patch-myapp-insert)
    [newsection]
    foo=bar
    
    #(Config::Patch-myapp-insert)
    [section]
    blah blah

=item C<update>

Finds existing hunks and updates them with new values.

        # Update "myapp" hunk with new value
    my $hunk = Config::Patch::Hunk->new(
        key   => "myapp",
        mode  => "update",
        text  => "foo=woot", );

While this could be done by removing the hunk via C<eject> and then
adding it, C<update> makes sure the hunk stays exactly in place.

=back

=item C<regex>

Patch locations are all lines (or line ranges for multi-line regexes) 
matching the regular expression in C<regex> (qr/.../).

=item C<text()>

The content text the hunk adds to the data.

=back

=head2 Stripping everything but the hunks

The method C<$patcher-E<gt>patches_only()> will trim the surrounding
text from the data and just leave the patched sections in place.

=head2 Patches in Memory

Config::Patcher isn't limited to operating on files, you can just as well
operate solely in memory. The C<data()> method is a read/write accessor
to the data string the patcher works on.

    my $patcher = Config::Patch->new();
    $patcher->data( "line1\n", "line2\n" );

    $patcher->apply( $patch );
    print $patcher->data();

=head2 Updating patches

Applying a patch if a patch with the same key has already been
applied results in an error. For this purpose, use a hunk with
the mode field set to 'update'.

=head2 Newline issues

Config::Patch operates line-based, which requires that every line
ends with a newline. If you read in a file with trailing characters that
aren't ended with a newline, Config::Patch will add a newline at the
end.

The same applies for patches. Patch lines need to be terminated by a newline,
if you forget to specify them that way, Config::Patch will correct it for you.

=head2 Examining patches

To find out what hunks have been applied to the data, use the C<parse()>
method which returns a list of hunks:

    for my $hunk ( $patcher->parse() ) {
        print "Found hunk: ", $hunk->text(), "\n";
    }

Even after applying a hunk, you have access to a number of updated fields:

    print "Hunk inserted between positions ",
          $hunk->pos_start(), 
          " and ",
          $hunk->pos_end(), 
          "\n";

Both C<pos_start> and C<pos_end> refer to offsets I<including> the markers
Config::Patch applies around the content. To find the location of
the content of the patch, use C<pos_content_start> and C<pos_content_end>
instead. To obtain the entire text of the hunk (including patch headers),
use C<as_string()>.

=head2 Specify a different comment character

C<Config::Patch> assumes that lines starting with a comment
character are ignored by their applications. This is important,
since C<Config::Patch> uses comment lines to hides vital patch
information in them for recovering from patches later on.

By default, this comment character is '#', usable for file formats
like YAML, Makefiles, and Perl. 
To change this default and use a different character, specify the
comment character like

    my $patcher = Config::Patch->new( 
        comment_char => ";",  # comment char is now ";"
        # ...
    );

in the constructor call. The command line script C<config-patch>
expects a different comment character with the C<-C> option,
check its manpage for details.
Make sure to use the same comment character
for patching and unpatching, otherwise chaos will ensue.

Other than that, C<Config::Patch> is format-agnostic. 
If you need to pay attention
to the syntax of the configuration file to be patched, create a subclass
of C<Config::Patch> and put the format specific logic there.

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2010 by Mike Schilli. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
