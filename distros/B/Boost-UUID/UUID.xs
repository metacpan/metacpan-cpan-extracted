#include <boost/uuid/uuid.hpp>            // uuid class
#include <boost/uuid/uuid_generators.hpp> // generators
#include <boost/uuid/uuid_io.hpp>         // streaming operators etc.
#include <xs/xs.h>

using namespace boost::uuids;

MODULE = Boost::UUID                PACKAGE = Boost::UUID
PROTOTYPES: DISABLE

std::string random_uuid(){
    auto uuid = random_generator()();
    RETVAL =  to_string(uuid);
}

std::string nil_uuid(){
    auto uuid = nil_generator()();
    RETVAL =  to_string(uuid);
}

std::string string_uuid(std::string input_str ){
    if ( input_str.empty() ) {
        RETVAL = std::string();
        return;
     }

    string_generator gen;
    auto u1 = nil_generator()();

    try {
        u1 = gen(input_str);
    }catch (const boost::exception& ex) {

    };

    RETVAL =  to_string(u1);
}

std::string name_uuid(std::string dns_name ){
    auto uuid = name_generator(boost::uuids::uuid())(dns_name);
    RETVAL =  to_string(uuid);
}
