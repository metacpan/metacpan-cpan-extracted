role Collectionable {
    # Should be an object of type Agent
    has owner;
    has value ( is => rw );
    has status   (
        enum        => ['for_sale', 'sold'],
        handles     => 1,
        default     => 'for_sale'
    );
    method belongs_to {
        return $self->owner;
    };
}
