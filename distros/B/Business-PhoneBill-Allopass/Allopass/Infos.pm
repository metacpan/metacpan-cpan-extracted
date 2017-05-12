package Business::PhoneBill::Allopass::Infos;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = "1.01";


=head1 NAME

Billing::Allopass::Infos - A simple class for infos retrieving from provided Allopass HTML code

=head1 SYNOPSIS

    use Business::PhoneBill::Allopass::Infos;
  
    my $ap='<table... .../table>';  # Allopass HTML code
    my $hapnfo=Business::PhoneBill::Allopass::Infos->new(\$ap);
    print $hapnfo->doc_id;
  
=head1 DESCRIPTION

    
    

=head1 CONSTRUCTOR

=over 4

=item B<new> - Class constructor.

    Business::PhoneBill::Allopass::Infos->new($ap);

OR
    
    Business::PhoneBill::Allopass::Infos->new(\$ap); # Prefered way

=cut

sub new {
    my $class=shift;
    my $ap   =shift;
    my $self={
        paliers =>    {},
        site_id =>    '',
        doc_id  =>    '',
        cc_acc  =>    '',
    };
    $self=bless $self, $class;
    $self->_parse($ap);
    $self;
}

=back

=head1 PROPERTIES

=over 4

=item B<site_id> - Retrieves the site id.

=item B<doc_id> - Retrieves the document id.

=item B<paliers> - Array of countries.

=item B<palier> - Provides ID for given country.

=cut

sub site_id {shift->{site_id}}
sub doc_id  {shift->{doc_id}}
sub paliers { (keys %{shift->{paliers}}) }
sub palier  {
    my $self=shift;
    my $pays=shift || '';
    $self->{paliers}{lc($pays)} || 0;
}

=back

=head1 METHODS

=over 4

=item B<link_num> gives the Allopass's call number page http address for given country

=cut

sub link_num {
    my $self=shift;
    my $pays=shift || '';
    return '' unless $self->{paliers}{lc($pays)};
    'http://www.allopass.com/show_accessv2.php4?PALIER='.$self->{paliers}{lc($pays)}.'&SITE_ID='.$self->{site_id}.'&DOC_ID='.$self->{doc_id};
}

=item B<link_cc> gives the Allopass's credit card page http address for given language

=cut

sub link_cc {
    my $self=shift;
    my $lang=shift || ''; $lang=_fix_lang($lang);
    
    return '' unless $self->{cc_acc};
    # 'https://secure.allopass.com/show_ccard.php4?LG=FR&SITE_ID='.$self->{site_id}.'&DOC_ID='.$self->{doc_id};
    'https://secure.allopass.com/show_ccard.php4?LG='.$lang.'&SITE_ID='.$self->{site_id}.'&DOC_ID='.$self->{doc_id};
}

=back

=head1 AUTHOR

Bernard Nauwelaerts <bpn#it-development%be>

=head1 LICENSE

GPL.  Enjoy !
See COPYING for further informations on the GPL.

=cut

### Private --------------------------------------------------------------------
sub _parse {
    my $self=shift;
    my $ap  =shift;
    $ap=$$ap if ref $ap;
    $ap=~s/\n//g; $ap=~s/\/a>/\/a>\n/g;
    foreach (split(/\n/, $ap)) {
        if (m!http://www.allopass.com/show_accessv2.php4\?PALIER=(\d+)?\&SITE_ID=(\d+)?\&DOC_ID=(\d+)?\&LG=(..)','phone'.*?><img .*? src="http://www.allopass.com/imgweb/common/flag_(..)?.gif".*?></a>!) {
            $self->{paliers}{lc($5)} = $1;
            $self->{site_id}=$2;
            $self->{doc_id}=$3;
        } elsif (m!https://secure.allopass.com/show_ccard.php4\?LG=..&SITE_ID=(\d+)?\&DOC_ID=(\d+)?!) {
            $self->{cc_acc}=1;
        }
    }
}

### Piske c cretins affichent une page vide pour l'achat de codes par carte bancaire si la lang n'est pas bonne :-(
sub _fix_lang {
    my $lang=shift;
    $lang=uc($lang);
    if ($lang eq 'FR' || $lang eq 'ES' || $lang eq 'UK') {
        return $lang;
    }
    'UK'
}
1;