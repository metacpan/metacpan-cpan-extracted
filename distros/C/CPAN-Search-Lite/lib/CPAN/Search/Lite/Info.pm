package CPAN::Search::Lite::Info;
use strict;
use warnings;
use Storable;
use CPAN::DistnameInfo;
use File::Spec::Functions;
use Compress::Zlib;
use File::Listing;
use File::Basename;
use Safe;
use CPAN::Search::Lite::Util qw(vcmp);
our ($ext);
$ext = qr/\.(tar\.gz|tar\.Z|tgz|zip)$/;
our $VERSION = 0.77;

sub new {
    my ($class, %args) = @_;
    die "Must supply the top-level CPAN directory" unless $args{CPAN};
    my $self = {CPAN => $args{CPAN}, ignore => $args{ignore},
                dists => {}, auths => {}, mods => {}};
    bless $self, $class;
}

sub fetch_info {
    my $self = shift;
    $self->mailrc();
    $self->dists_and_mods();
    return 1;
}

sub dists_and_mods {
    my $self = shift;
    my $modlist = $self->modlist();
    my ($packages, $cpan_files) = $self->packages();

    my ($dists, $mods);
    my $ignore = $self->{ignore};
    my $pat;
    if ($ignore and ref($ignore) eq 'ARRAY') {
      $pat = join '|', @$ignore;
    }
    foreach my $cpan_file (keys %$cpan_files) {
        next if $cpan_file =~ /Spreadsheet-WriteExcel-WebPivot2/;
        my $d = CPAN::DistnameInfo->new($cpan_file);
        next unless ($d->maturity eq 'released');
        my $dist = $d->dist;
        my $version = $d->version;
        my $cpanid = $d->cpanid;
        my $filename = $d->filename;
        unless ($dist and $version and $cpanid) {
            print "No dist_name/version/cpanid for $cpan_file: skipping\n";
            delete $cpan_files->{$cpan_file};
            next;
        }
        # ignore specified dists
        if ($pat and ($dist =~ /^($pat)$/)) {
             delete $cpan_files->{$cpan_file};
             print "Ignoring $dist\n";
             next;
        }
        if (not $dists->{$dist} or 
            vcmp($version, $dists->{$dist}->{version}) > 0) {
            $dists->{$dist}->{version} = $version;
            $dists->{$dist}->{filename} = $filename;
            $dists->{$dist}->{cpanid} = $cpanid;
        }
    }

    my $wanted;
    foreach my $dist (keys %$dists) {
        $wanted->{basename($dists->{$dist}->{filename})} = $dist;
    }
    $self->parse_ls($dists, $wanted);
    foreach my $module (keys %$packages) {
        my $file = basename($packages->{$module}->{file});
        my $dist;
        unless ($dist = $wanted->{$file} and $dists->{$dist}) {
            delete $packages->{$module};
            next;
        }
        $mods->{$module}->{dist} = $dist;
        $dists->{$dist}->{modules}->{$module}++; 
        my $version = $packages->{$module}->{version};
        $mods->{$module}->{version} = $version;
        if (my $info = $modlist->{$module}) {
            if (my $desc = $info->{description}) {
                $mods->{$module}->{description} =  $desc;
                (my $trial_dist = $module) =~ s!::!-!g;
                if ($trial_dist eq $dist) {
                    $dists->{$dist}->{description} = $desc;
                }
            }
            if (my $chapterid = $info->{chapterid} + 0) {
                $mods->{$module}->{chapterid} = $chapterid;
                (my $sub_chapter = $module) =~ s!^([^:]+).*!$1!;
                $dists->{$dist}->{chapterid}->{$chapterid}->{$sub_chapter}++;
            } 
            my %dslip = ();
            for (qw(statd stats statl stati statp) ) {
                next unless defined $info->{$_};
                $dslip{$_} = $info->{$_};
            }
            if (%dslip) {
                my $value = '';
                foreach (qw(d s l i p)) {
                    my $key = 'stat' . $_;
                    $value .= (defined $dslip{$key} ?
                               $dslip{$key} : '?');
                }
                $mods->{$module}->{dslip} = $value;
            }
        }
    }
    $self->{dists} = $dists;
    $self->{mods} = $mods;
}
  
sub parse_ls {
    my ($self, $dists, $wanted) = @_;
    my $ls = catfile $self->{CPAN}, 'indices', 'ls-lR.gz';
    print "Reading information from $ls\n";
    my ($buffer, $dir, $lines, $listing);
    my $gz = gzopen($ls, 'rb')
        or die "Cannot open $ls: $gzerrno";
    while ($gz->gzreadline($buffer) > 0) {
        next unless $buffer =~ /^-r.*$ext/;
        push @$lines, $buffer;
    }
    die "Error reading from $ls: $gzerrno" . ($gzerrno+0)
        if $gzerrno != Z_STREAM_END;
    $gz->gzclose();
    $dir = parse_dir($lines, '+0000');
    for (@$dir) {
        next unless ($_->[1] eq 'f' and $wanted->{$_->[0]});
        $listing->{$_->[0]} = {size => $_->[2], time => $_->[3]};
    }
    foreach my $dist (keys %$dists) {
        my $filename = $dists->{$dist}->{filename};
        my $base = basename($filename);
        unless ($listing->{$base} and $listing->{$base}->{size}
                and $listing->{$base}->{time}) {
            delete $dists->{$dist};
            next;
        }
        my ($mday, $mon, $year) = (gmtime($listing->{$base}->{time}))[3,4,5];
        $mon++;
        $year += 1900;
        $dists->{$dist}->{filename} = $filename;
        $dists->{$dist}->{size} = $listing->{$base}->{size};
        $dists->{$dist}->{date} = "$year-$mon-$mday";
    }
}

sub modlist {
    my $self = shift;
    my $mod = catfile $self->{CPAN}, 'modules', '03modlist.data.gz';
    print "Reading information from $mod\n";
    my $lines = zcat($mod);
    while (@$lines) {
        my $shift = shift(@$lines);
        last if $shift =~ /^\s*$/;
    }
    push @$lines, q{CPAN::Modulelist->data;};
    my($comp) = Safe->new("CPAN::Safe1");
    my($eval) = join("\n", @$lines);
    my $ret = $comp->reval($eval);
    die "Cannot eval $mod: $@" if $@;
    return $ret;
}

sub packages {
    my $self = shift;
    my $packages = catfile $self->{CPAN}, 'modules', 
        '02packages.details.txt.gz';
    print "Reading information from $packages\n";
    my $lines = zcat($packages);
    while (@$lines) {
        my $shift = shift(@$lines);
        last if $shift =~ /^\s*$/;
    }
    my ($ret, $cpan_files);
    foreach (@$lines) {
	my ($mod,$version,$file,$comment) = split " ", $_, 4;
        $version = undef if $version eq 'undef';
        $ret->{$mod} = {version => $version, file => $file};
        $cpan_files->{$file}++;
    }
    return ($ret, $cpan_files);
}

sub mailrc {
    my $self = shift;
    my $mailrc = catfile $self->{CPAN}, 'authors', '01mailrc.txt.gz';
    print "Reading information from $mailrc\n";
    my $lines = zcat($mailrc);
    my $auths;
    foreach (@$lines) {
	#my($userid,$fullname,$email) =
	    #m/alias\s+(\S+)\s+\"([^\"\<]+)\s+\<([^\>]+)\>\"/;
        my ($userid, $authinfo) = m/alias\s+(\S+)\s+\"([^\"]+)\"/;
        next unless $userid;
        my ($fullname, $email);
        if ($authinfo =~ m/([^<]+)\<(.*)\>/) {
            $fullname = $1;
            $email = $2;
        }
        else {
            $fullname = '';
            $email = lc($userid) . '@cpan.org';
        }
       $auths->{$userid} = {fullname => trim($fullname),
                            email => trim($email)};
    }
    $self->{auths} = $auths;
}

sub zcat {
    my $file = shift;
    my ($buffer, $lines);
    my $gz = gzopen($file, 'rb')
        or die "Cannot open $file: $gzerrno";
    while ($gz->gzreadline($buffer) > 0) {
        push @$lines, $buffer;
    }
    die "Error reading from $file: $gzerrno" . ($gzerrno+0)
        if $gzerrno != Z_STREAM_END;
    $gz->gzclose();
    return $lines;
}

sub trim {
    my $string = shift;
    return '' unless $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\s+/ /g;
    return $string;
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Info - extract information from CPAN indices

=head1 DESCRIPTION

This module extracts information from the CPAN indices
F<$CPAN/indices/ls-lR.gz>, F<$CPAN/modules/03modlist.data.gz>,
F<$CPAN/modules/02packages.details.txt.gz>, and
F<$CPAN/authors/01mailrc.txt.gz>. If a local CPAN mirror
isn't present, it will use the files fetched from a remote CPAN mirror
under C<CPAN> by L<CPAN::Search::Lite::Index>.

A C<CPAN::Search::Lite::Info> object is created with

    my $info = CPAN::Search::Lite::Info(CPAN => $cpan);

where C<$cpan> specifies the top-level CPAN directory
underneath which the index files are found. Calling

    $info->fetch_info();

will result in the object being populated with 3 hash references:

=over 3

=item * C<$info-E<gt>{dists}>

This contains information on distributions. Keys of this hash
reference are the distribution names, with the associated value being a
hash reference with keys of 

=over 3

=item C<version> - the version of the CPAN file

=item C<filename> - the CPAN filename

=item C<cpanid> - the CPAN author id

=item C<description> - a description, if available

=item C<size> - the size of the file

=item C<date> - the last modified date (I<YYYY/MM/DD>) of the file

=item C<md5> - the CPAN md5 checksum of the file

=item C<modules> - specifies the modules present in the distribution:

  for my $module (keys %{$info->{$distname}->{modules}}) {
    print "Module: $module\n";
  }

=item C<chapterid> - specifies the chapterid and the subchapter 
for the distribution:

  for my $id (keys %{$info->{$distname}->{chapterid}}) {
    print "For chapterid $id\n";
    for my $sc (keys %{$info->{$distname}->{chapterid}->{$id}}) {
      print "   Subchapter: $sc\n";
    }
  }

=item C<requires> - a hash reference whose keys are the names of
prerequisite modules required for the package and whose values are
the associated module versions. This information comes from the
F<META.yml> file processed in L<CPAN::Search::Lite::Extract>.

=back

=item * C<$info-E<gt>{mods}>

This contains information on modules. Keys of this hash
reference are the module names, with the associated values being a
hash reference with keys of 

=over 3

=item C<dist> - the distribution name containing the module

=item C<version> - the version

=item C<description> - a description, if available

=item C<chapterid> - the chapter id of the module, if present

=item C<dslip> - a 5 character string specifying the dslip 
(development, support, language, interface, public licence) information.

=back

=item * C<$info-E<gt>{auths}>

This contains information on CPAN authors. Keys of this hash
reference are the CPAN ids, with the associated value being a
hash reference with keys of 

=over 3

=item C<fullname> - the author's full name

=item C<email> - the author's email address

=back

=back

=head1 SEE ALSO

L<CPAN::Search::Lite::Index>

=cut

