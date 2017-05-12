
package XPT::File;

use strict;
use warnings;

use base qw(XPT);

use Carp;

use constant MAGIC      => "XPCOM\nTypeLib\r\n\032";

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $magic = XPT::ReadBuffer($r_buffer, $r_offset, length(MAGIC));
    die "libxpt: bad magic header in input file; found '",$magic,"', expected '",MAGIC,"'\n"
            unless ($magic eq MAGIC);

    my $major_version = XPT::Read8($r_buffer, $r_offset);
    my $minor_version = XPT::Read8($r_buffer, $r_offset);
    die "libxpt: newer version ",$major_version,".",$minor_version,"\n"
            unless ($major_version == 1);

    my $num_interfaces = XPT::Read16($r_buffer, $r_offset);
    my $file_length = XPT::Read32($r_buffer, $r_offset);

    die "libxpt: File length in header does not match actual length. File may be corrupt\n"
            if ($file_length != length $$r_buffer);

    my $interface_directory_offset = XPT::Read32($r_buffer, $r_offset);
    $XPT::data_pool_offset = XPT::Read32($r_buffer, $r_offset);

    my @annotations = ();
    my %interface_iid = ();
    my %interface_iid_nul = ();
    eval {
        my $annotation = XPT::Annotation::demarshal($r_buffer, $r_offset);
        push @annotations, $annotation;
        while (!$annotation->{is_last}) {
            $annotation = XPT::Annotation::demarshal($r_buffer, $r_offset);
            push @annotations, $annotation;
        }

        my $offset = $interface_directory_offset - 1;
        while ($num_interfaces --) {
            my $entry = XPT::InterfaceDirectoryEntry::demarshal($r_buffer, \$offset);
            if ($entry->{iid}->_is_nul()) {
                my $fullname = ($entry->{name_space} || q{}) . '::' . $entry->{name};
                $interface_iid_nul{$fullname} = $entry;
            }
            else {
                $interface_iid{$entry->{iid}->stringify()} = $entry;
            }
        }
    };
    if ($@) {
        $XPT::demarshal_retcode = 1;
        if ($XPT::demarshal_not_abort) {
            warn $@;
        }
        else {
            die $@;
        }
    }

    return new XPT::File(
            magic                   => $magic,
            major_version           => $major_version,
            minor_version           => $minor_version,
            interface_iid_nul       => \%interface_iid_nul,
            interface_iid           => \%interface_iid,
            annotations             => \@annotations,
            file_length             => $file_length,
            data_pool_offset        => $XPT::data_pool_offset,
    )->_revolve();
}

sub _interface_directory {
    my $self = shift;
    my @list = ();
    foreach (sort keys %{$self->{interface_iid_nul}}) {
        my $entry = $self->{interface_iid_nul}->{$_};
        push @list, $entry;
    }
    foreach (sort keys %{$self->{interface_iid}}) {
        my $entry = $self->{interface_iid}->{$_};
        push @list, $entry;
    }
    return @list;
}

sub _revolve {
    my $self = shift;
    my @interface_directory = $self->_interface_directory();
    foreach my $itf (values %{$self->{interface_iid}}) {
        next unless (defined $itf->{interface_descriptor});     # ISupport
        my $desc = $itf->{interface_descriptor};
        my $idx_parent = $desc->{parent_interface_index};
        if ($idx_parent) {
            if ($idx_parent > scalar(@interface_directory)) {
                warn "parent_interface_index out of range! ($idx_parent)\n";
                $XPT::demarshal_retcode = 1;
            }
            $desc->{parent_interface} = $interface_directory[$idx_parent - 1];
        }
        foreach my $method (@{$desc->{method_descriptors}}) {
            foreach my $param (@{$method->{params}}) {
                my $type = $param->{type};
                if ($type->{tag} == XPT::InterfaceTypeDescriptor) {
                    my $idx = $type->{interface_index};
                    if ($idx > scalar(@interface_directory)) {
                        warn "interface_index out of range! ($idx)\n";
                        next;
                    }
                    $type->{interface} = $interface_directory[$idx - 1];
                }
            }
        }
    }
    return $self;
}

sub marshal {
    my $self = shift;

    my $header_size = length(MAGIC) + 1 + 1 + 2 + 4 + 4 + 4;
    my $annotations = q{};
    foreach (@{$self->{annotations}}) {
        $annotations .= $_->marshal();
    }
#   while ( ($header_size + length($annotations)) % 4) {
#       $annotations .= "\0";
#   }
    $header_size += length($annotations);
    my $interface_directory_offset = $header_size + 1;
    my @interface_directory = $self->_interface_directory();
    $XPT::data_pool = q{};
    my $interface_directory = q{};
    foreach (@interface_directory) {
        $interface_directory .= $_->marshal();
    }

    my $data_pool_offset = $header_size + length($interface_directory);
    my $file_length = $header_size + length($interface_directory) + length($XPT::data_pool);
    my $buffer = $self->{magic};
    $buffer .= XPT::Write8($self->{major_version});
    $buffer .= XPT::Write8($self->{minor_version});
    $buffer .= XPT::Write16(scalar(@interface_directory));
    $buffer .= XPT::Write32($file_length);
    $buffer .= XPT::Write32($interface_directory_offset);
    $buffer .= XPT::Write32($data_pool_offset);
    $buffer .= $annotations;
    $buffer .= $interface_directory;
    $buffer .= $XPT::data_pool;
    return $buffer;
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{} unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;
    my $more_indent = $new_indent . q{ } x 3;

    my @interface_directory = $self->_interface_directory();
    my $str = $indent . "Header:\n";
    if ($XPT::stringify_verbose) {
        $str .= $new_indent . "Magic beans:           ";
        foreach (split //, $self->{magic}) {
            $str .= sprintf("%02x", ord($_));
        }
        $str .= "\n";
        if ($self->{magic} eq MAGIC) {
            $str .= $new_indent . "                       PASSED\n";
        }
        else {
            $str .= $new_indent . "                       FAILED\n";
        }
    }
    $str .= $new_indent . "Major version:         " . $self->{major_version} . "\n";
    $str .= $new_indent . "Minor version:         " . $self->{minor_version} . "\n";
    $str .= $new_indent . "Number of interfaces:  " . scalar(@interface_directory) . "\n";
    if ($XPT::stringify_verbose) {
        $str .= $new_indent . "File length:           " . $self->{file_length} . "\n"
                if (exists $self->{file_length});
        $str .= $new_indent . "Data pool offset:      " . $self->{data_pool_offset} . "\n"
                if (exists $self->{data_pool_offset});
        $str .= "\n";
    }

    my $nb = -1;
    $str .= $new_indent . "Annotations:\n";
    foreach (@{$self->{annotations}}) {
        $nb ++;
        $str .= $more_indent . "Annotation #" . $nb;
        $str .= $_->stringify($new_indent);
    }
    if ($XPT::stringify_verbose) {
        $str .= $more_indent . "Annotation #" . $nb . " is the last annotation.\n";
    }

    $XPT::param_problems = 0;
    $nb = 0;
    $str .= "\n";
    $str .= $indent . "Interface Directory:\n";
    foreach my $entry (@interface_directory) {
        if ($XPT::stringify_verbose) {
            $str .= $new_indent . "Interface #" . $nb ++ . ":\n";
            $str .= $entry->stringify($new_indent . $new_indent, $self);
        }
        else {
            $str .= $entry->stringify($new_indent, $self);
        }
    }
    if ($XPT::param_problems) {
        $str .= "\nWARNING: ParamDescriptors are present with "
             .  "bad in/out/retval flag information.\n"
             .  "These have been marked with 'XXX'.\n"
             .  "Remember, retval params should always be marked as out!\n";
    }

    return $str;
}

sub add_annotation {
    my $self = shift;
    my ($annotation) = @_;
    $annotation->{is_last} = 0;
    $self->{annotations} = [] unless (exists $self->{annotations});
    push @{$self->{annotations}}, $annotation;
}

sub terminate_annotations {
    my $self = shift;
    if (exists $self->{annotations}) {
        ${$self->{annotations}}[-1]->{is_last} = 1;
    }
    else {
        my $annotation = new XPT::Annotation(
                is_last                 => 1,
                tag                     => 0,
        );
        $self->{annotations} = [ $annotation ];
    }
}

sub add_interface {
    my $self = shift;
    my ($entry) = @_;
    $self->{interface_iid_nul} = {} unless (exists $self->{interface_iid_nul});
    $self->{interface_iid} = {} unless (exists $self->{interface_iid});
    my $fullname = $entry->{name_space} . '::' . $entry->{name};
    if ($entry->{iid}->_is_nul()) {
        return if (exists $self->{interface_iid_nul}->{$fullname});
        foreach (values %{$self->{interface_iid}}) {
            return if ($fullname eq $_->{name_space} . '::' . $_->{name});
        }
        $self->{interface_iid_nul}->{$fullname} = $entry;
    }
    else {
        my $iid = $entry->{iid}->stringify();
        if (exists $self->{interface_iid}->{$iid}) {
            return if (defined $self->{interface_iid}->{$iid}->{interface_descriptor});
        }
        else {
            delete $self->{interface_iid_nul}->{$fullname}
                    if (exists $self->{interface_iid_nul}->{$fullname});
            foreach (values %{$self->{interface_iid}}) {
                croak "ERROR: found duplicate definition of interface $fullname with iids \n"
                        if ($fullname eq $_->{name_space} . '::' . $_->{name});
            }
        }
        $self->{interface_iid}->{$iid} = $entry;
    }
}

sub indexe {
    my $self = shift;
    foreach my $itf (values %{$self->{interface_iid}}) {
        next unless (defined $itf->{interface_descriptor});     # ISupport
        my $desc = $itf->{interface_descriptor};
        $desc->{parent_interface_index} = $self->_find_itf($desc->{parent_interface});
        foreach my $method (@{$desc->{method_descriptors}}) {
            foreach my $param (@{$method->{params}}) {
                my $type = $param->{type};
                if ($type->{tag} == XPT::InterfaceTypeDescriptor) {
                    $type->{interface_index} = $self->_find_itf($type->{interface});
                }
            }
        }
    }
}

sub _find_itf {
    my $self = shift;
    my ($itf) = @_;
    return 0 unless (defined $itf);
    my @interface_directory = $self->_interface_directory();
    my $idx = 1;
    foreach (@interface_directory) {
        if (ref $itf) {
            if        ( $_->{name_space} eq $itf->{name_space}
                    and $_->{name} eq $itf->{name} ) {
                return $idx;
            }
        }
        else {
            if ($itf eq $_->{name_space} . '::' . $_->{name}) {
                return $idx;
            }
        }
        $idx ++;
    }
    if (ref $itf) {
        croak "ERROR: interface $itf->{name_space}::$itf->{name} not found\n";
    }
    else {
        croak "ERROR: interface $itf not found\n";
    }
}

1;

