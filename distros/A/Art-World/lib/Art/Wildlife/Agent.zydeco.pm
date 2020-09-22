include Behavior::Active;

class Agent with Active {
    # Should be required but will be moved to the Crudable area
    has id         ( type => Int );
    has name!       ( type => Str );
    has reputation ( type => Int );

    include Artist;
    include Collector;
}
