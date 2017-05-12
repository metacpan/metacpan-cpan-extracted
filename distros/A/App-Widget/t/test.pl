$conf = {
  Serializer => {
    default => {
    },
    xml => {
      serializerClass => "App::Serializer::XMLSimple",
    },
    xml2 => {
      serializerClass => "App::Serializer::XMLDumper",
    },
    ini => {
      serializerClass => "App::Serializer::Ini",
    },
    prop => {
      serializerClass => "App::Serializer::Properties",
    },
  },
  CallDispatcher => {
    default => {
    },
  },
  SharedDatastore => {
    default => {
    },
  },
  MessageDispatcher => {
    default => {
    },
  },
  ResourceLocker => {
    default => {
    },
  },
  Authentication => {
    default => {
    },
  },
  Authorization => {
    default => {
    },
  },
  SessionObject => {
    default => {
    },
    stephen => {
    }
  },
};
