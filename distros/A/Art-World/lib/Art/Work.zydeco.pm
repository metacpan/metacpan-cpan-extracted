class Work {
    has creation_date;
    has creator (
        is => ro,
        # ArrayRed of Artists
        type => ArrayRef[ Object ]
       );
    include Artwork;
}
