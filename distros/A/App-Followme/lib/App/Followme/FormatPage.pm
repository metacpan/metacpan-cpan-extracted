package App::Followme::FormatPage;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile);
use App::Followme::FIO;

our $VERSION = "1.93";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            data_pkg => 'App::Followme::WebData',
    );
}

#----------------------------------------------------------------------
# Modify pages to match the most recently modified page

sub run {
    my ($self, $folder) = @_;

    $self->update_folder($folder);
    return;
}

#----------------------------------------------------------------------
# Compute checksum for constant sections of page

sub checksum_prototype {
    my ($self, $prototype, $prototype_path) = @_;

    my $md5 = Digest::MD5->new;

    my $block_handler = sub {
        my ($blockname, $locality, $blocktext) = @_;
        $md5->add($blocktext) if exists $prototype_path->{$locality};
    };

    my $prototype_handler = sub {
        my ($blocktext) = @_;
        $md5->add($blocktext);
        return;
    };

    $self->parse_blocks($prototype, $block_handler, $prototype_handler);
    return $md5->hexdigest;
}

#----------------------------------------------------------------------
# Get the prototype path for the current directory

sub get_prototype_path {
    my ($self, $filename) = @_;

    $filename = rel2abs($filename);
    $filename = abs2rel($filename, $self->{top_directory});
    my @path = splitdir($filename);
    pop(@path);

    my %prototype_path = map {$_ => 1} @path;
    return \%prototype_path;
}

#----------------------------------------------------------------------
# Parse fields out of section tag

sub parse_blockname {
    my ($self, $str) = @_;

    my ($blockname, $in, $locality) = split(/\s+/, $str);

    if ($in) {
        die "Syntax error in block ($str)"
            unless $in eq 'in' && defined $locality;
    } else {
        $locality = '';
    }

    return ($blockname, $locality);
}

#----------------------------------------------------------------------
# This code considers the surrounding tags to be part of the block

sub parse_blocks {
    my ($self, $page, $block_handler, $prototype_handler) = @_;

    my $locality;
    my $block = '';
    my $blockname = '';
    my @tokens = split(/(<!--\s*(?:section|endsection)\s+.*?-->)/, $page);

    foreach my $token (@tokens) {
        if ($token =~ /^<!--\s*section\s+(.*?)-->/) {
            die "Improperly nested block ($token)\n" if $blockname;

            ($blockname, $locality) = $self->parse_blockname($1);
            $block .= $token

        } elsif ($token =~ /^<!--\s*endsection\s+(.*?)-->/) {
            my ($endname) = $self->parse_blockname($1);
            die "Unmatched ($token)\n"
                if $blockname eq '' || $blockname ne $endname;

            $block .= $token;
            $block_handler->($blockname, $locality, $block);

            $block = '';
            $blockname = '';

        } else {
            if ($blockname) {
                $block .= $token;
            } else {
                $prototype_handler->($token);
            }
        }
    }

    die "Unmatched block (<!-- section $blockname -->)\n" if $blockname;
    return;
}

#----------------------------------------------------------------------
# Extract named blocks from a page

sub parse_page {
    my ($self, $page) = @_;

    my $blocks = {};
    my $block_handler = sub {
        my ($blockname, $locality, $blocktext) = @_;
        if (exists $blocks->{$blockname}) {
            die "Duplicate block name ($blockname)\n";
        }
        $blocks->{$blockname} = $blocktext;
        return;
    };

    my $prototype_handler = sub {
        return;
    };

    $self->parse_blocks($page, $block_handler, $prototype_handler);
    return $blocks;
}

#----------------------------------------------------------------------
# Determine if page matches prototype or needs to be updated

sub unchanged_prototype {
    my ($self, $prototype, $page, $prototype_path) = @_;

    my $prototype_checksum =
        $self->checksum_prototype($prototype, $prototype_path);

    my $page_checksum =
        $self->checksum_prototype($page, $prototype_path);

    my $unchanged;
    if ($prototype_checksum eq $page_checksum) {
        $unchanged = 1;
    } else {
        $unchanged = 0;
    }

    return $unchanged;
}

#----------------------------------------------------------------------
# Update file using prototype

sub update_file {
    my ($self, $file, $prototype, $prototype_path) = @_;

    my $page = fio_read_page($file);
    die "Couldn't read $file" unless defined $page;

    # Check for changes before updating page
    return 0 if $self->unchanged_prototype($prototype, $page, $prototype_path);

    $page = $self->update_page($page, $prototype, $prototype_path);

    my $modtime = fio_get_date($file);
    fio_write_page($file, $page);
    fio_set_date($file, $modtime);

    return 1;
}

#----------------------------------------------------------------------
# Perform all updates on the directory

sub update_folder {
    my ($self, $folder, $prototype_file) = @_;

    my $index_file = $self->to_file($folder);
    my ($prototype_path, $prototype);
    my $modtime = fio_get_date($folder);

    my $files = $self->{data}->build('files', $index_file);
    my $file = shift(@$files);

    if ($file) {
        # The first update uses a file from the  directory above
        # as a prototype, if one is found

        $prototype_file ||= $self->find_prototype($folder, 1);

        if ($prototype_file) {
            $prototype_path = $self->get_prototype_path($prototype_file);
            my $prototype = fio_read_page($prototype_file);

            eval {$self->update_file($file, $prototype, $prototype_path)};
            $self->check_error($@, $file);
        }

        # Subsequent updates use the most recently modified file
        # in the directory as the prototype

        $prototype_file = $file;
        $prototype_path = $self->get_prototype_path($prototype_file);
        $prototype = fio_read_page($prototype_file);
    }

    my $changes = 0;
    foreach my $file (@$files) {
        my $change;
        eval {$change = $self->update_file($file, $prototype, $prototype_path)};
        $self->check_error($@, $file);

        last unless $change;
        $changes += 1;
    }

    fio_set_date($folder, $modtime);

    # Update files in subdirectory

    if ($changes || @$files == 0) {
        my $folders = $self->{data}->build('folders', $index_file);

        foreach my $subfolder (@$folders) {
            $self->update_folder($subfolder, $prototype_file);
        }
    }

    return;
}

#----------------------------------------------------------------------
# Parse prototype and page and combine them

sub update_page {
    my ($self, $page, $prototype, $prototype_path) = @_;
    $prototype_path = {} unless defined $prototype_path;

    my $output = [];
    my $blocks = $self->parse_page($page);

    my $block_handler = sub {
        my ($blockname, $locality, $blocktext) = @_;
        if (exists $blocks->{$blockname}) {
            if (exists $prototype_path->{$locality}) {
                push(@$output, $blocktext);
            } else {
                push(@$output, $blocks->{$blockname});
            }
            delete $blocks->{$blockname};
        } else {
            push(@$output, $blocktext);
        }
        return;
    };

    my $prototype_handler = sub {
        my ($blocktext) = @_;
        push(@$output, $blocktext);
        return;
    };

    $self->parse_blocks($prototype, $block_handler, $prototype_handler);

    if (%$blocks) {
        my $names = join(' ', sort keys %$blocks);
        die "Unused blocks ($names)\n";
    }

    return join('', @$output);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::FormatPages - Modify pages in a directory to match a prototype

=head1 SYNOPSIS

    use App::Followme::FormatPages;
    my $formatter = App::Followme::FormatPages->new($configuration);
    $formatter->run($directory);

=head1 DESCRIPTION

App::Followme::FormatPages updates the web pages in a folder to match the most
recently modified page. Each web page has sections that are different from other
pages and other sections that are the same. The sections that differ are
enclosed in html comments that look like

    <!-- section name-->
    <!-- endsection name -->

and indicate where the section begins and ends. When a page is changed, this
module checks the text outside of these comments. If that text has changed. the
other pages on the site are also changed to match the page that has changed.
Each page updated by substituting all its named blocks into corresponding block
in the changed page. The effect is that all the text outside the named blocks
are updated to be the same across all the web pages.

Updates to the named block can also be made conditional by adding an "in" after
the section name. If the folder name after the "in" is included in the
prototype_path hash, then the block tags are ignored, it is as if the block does
not exist. The block is considered as part of the constant portion of the
prototype. If the folder is not in the prototype_path, the block is treated as
any other block and varies from page to page.

    <!-- section name in folder -->
    <!-- endsection name -->

Text in conditional blocks can be used for navigation or other sections of the
page that are constant, but not constant across the entire site.

=head1 CONFIGURATION

The following parameters are used from the configuration:

=over 4

=item data_pkg

The name of the module that processes web files. The default value is
'App::Followme::WebData'.


The extension used by web pages. The default value is html

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
