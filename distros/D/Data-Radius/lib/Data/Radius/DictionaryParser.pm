package Data::Radius::DictionaryParser;

use v5.10;
use strict;
use warnings;

use IO::File ();
use File::Spec ();
use File::Basename ();

use Digest::MD5 qw(md5_hex);

# parser state
my $begin_vendor = undef;
my $begin_tlv = undef;
# map id to name, {vendor => {id => name}}
my %dict_id = ();
# map name to id
my %dict_attr = ();
my %dict_const_name = ();
my %dict_const_value = ();
my %dict_vendor_name = ();
my %dict_vendor_id = ();

my %included_files = ();

sub new {
    my $class = shift;
    cleanup();
    return bless {}, $class;
}

sub _create_dict_from_current_state {
    my ($self) = @_;

    return Data::Radius::Dictionary->new(
        attr_id     => { %dict_id },
        attr_name   => { %dict_attr },
        const_name  => { %dict_const_name },
        const_value => { %dict_const_value },
        vnd_name    => { %dict_vendor_name },
        vnd_id      => { %dict_vendor_id },
    );
}

sub parse_str_array {
    my ($self, $str_array) = @_;

    my $synthetic_fname = md5_hex( @{$str_array} );
    return if ( $included_files{$synthetic_fname} );
    $included_files{$synthetic_fname} = 1;

    # since it's not file on disk, all $INCLUDEs are built relative to CWD
    my $include_dir = $ENV{PWD} // '/';

    for my $line ( @{$str_array} ) {
        $self->_parse_line($line, $include_dir);
    }

    return $self->_create_dict_from_current_state;
}

sub parse_file {
    my ($self, $file) = @_;
    $self->_load_file($file);
    return $self->_create_dict_from_current_state;
}

sub _load_file {
    my ($self, $file) = @_;

    return undef if ( $included_files{$file} );

    my $fh = IO::File->new($file, 'r')
        || warn sprintf('Failed to open file "%s": %s', $file, $!);

    $included_files{$file} = 1;

    # INCLUDEs must be treated relatively to current file
    my $include_dir = File::Basename::dirname($file);

    while ( my $line = $fh->getline ) {
        $self->_parse_line($line, $include_dir);
    }

    $fh->close;

    return 1;
}

sub cleanup {
    my ($self) = @_;

    $begin_vendor = undef;
    $begin_tlv = undef;

    %dict_id = ();
    %dict_attr = ();
    %dict_const_name = ();
    %dict_const_value = ();
    %dict_vendor_name = ();
    %dict_vendor_id = ();
    %included_files = ();

    return undef;
}

sub _parse_line {
    my ($self, $line, $include_dir) = @_;
    $include_dir //= $ENV{PWD};

    my ($cmd, $name, $id, $type, $vendor, $has_tag, $has_options, $encrypt);

    $line =~ s/#.*$//;
    return undef if ( $line =~ /^\s*$/ );
    chomp $line;

    ($cmd, $name, $id, $type, $vendor) = split(/\s+/, $line);
    $cmd = lc($cmd);
    $has_options = 0;
    $has_tag = 0;
    $encrypt = undef;

    if ($cmd eq 'attribute') {
        # 'vendor' part can be an options - in FreeRADIUS dictionary format
        if ($vendor) {
            # there could be combination of both options:
            if ($vendor =~ /has_tag/) {
                $has_tag = 1;
                $has_options = 1;
            }
            if ($vendor =~ /encrypt=(\d)/) {
                #TODO encryption methods not supported now
                $encrypt = $1;
                $has_options = 1;
            }

            if ($has_options) {
                $vendor = undef;
            }
        }

        $vendor ||= $begin_vendor;

        if (exists $dict_attr{ $name }) {
            warn "Duplicated attribute name $name";
        }

        my $a_info = {
            id => $id,
            name => $name,
            type => $type,
            vendor => $vendor,
            has_tag => $has_tag,
            encrypt => $encrypt,
        };

        $dict_attr{ $name } = $a_info;

        if ($begin_tlv) {
            $a_info->{parent} = $begin_tlv;

            my $parent = $dict_attr{ $begin_tlv };
            $parent->{tlv_attr_name}{ $name } = $a_info;
            $parent->{tlv_attr_id}{ $id } = $a_info;
        }
        else {
            $dict_id{ $vendor // '' }{ $id } = $a_info;
        }
    }
    elsif ($cmd eq 'value') {
        # VALUE  NAS-Port-Type  Ethernet  15
        my ($v_name, $v_val) = ($id, $type);

        if (! exists $dict_attr{ $name }) {
            warn "Value for unknown attribute $name";
            next;
        }

        $dict_const_name{$name}{$v_val} = $v_name;
        $dict_const_value{$name}{$v_name} = $v_val;
    }
    elsif ($cmd eq 'vendor') {
        # VENDOR  Mikrotik  14988
        $dict_vendor_name{ $name } = $id;
        $dict_vendor_id{ $id } = $name;
    }
    elsif ($cmd eq 'begin-vendor') {
        # BEGIN-VENDOR  Huawei
        if (! exists $dict_vendor_name{ $name }) {
            warn "BEGIN-VENDOR $name - vendor id is unknown";
        }
        # set default vendor for all attributes below
        $begin_vendor = $name;
    }
    elsif ($cmd eq 'end-vendor') {
        # END-VENDOR  Laurel
        if (! $begin_vendor) {
            warn "END-VENDOR found without BEGIN-VENDOR";
            next;
        }
        $begin_vendor = undef;
    }
    elsif ($cmd eq 'begin-tlv') {
        if ($begin_tlv) {
            # no support for 2nd level
            warn "Nested BEGIN-TLV found";
        }

        # BEGIN-TLV WiMAX-PPAC
        # must be defined attribute with type 'tlv' first
        if (! exists $dict_attr{ $name }) {
            warn "Begin-tlv for unknown attribute $name";
            next;
        }
        if ($dict_attr{ $name }{type} ne 'tlv') {
            warn "Begin-tlv for attribute $name of non-tlv type";
            next;
        }
        $begin_tlv = $name;
    }
    elsif ($cmd eq 'end-tlv') {
        # END-TLV WiMAX-PPAC
        if (! $begin_tlv) {
            warn "END-TLV found without BEGIN-TLV";
            next;
        }
        $begin_tlv = undef;
    }
    elsif ($cmd eq '$include') {
        # $INCLUDE mikrotik
        # $INCLUDE /absolute/path/to/mikrotik

        # clear modifiers
        ($begin_vendor, $begin_tlv) = ();

        if (File::Spec->file_name_is_absolute($name)) {
            $self->_load_file($name);
        }
        else {
            $self->_load_file( File::Spec->catfile($include_dir, $name) );
        }
    }
    else {
        warn "Unknown command: $cmd";
    }

    return undef;
}


1;
