#include <upb/def.h>
#include <upb/bindings/googlepb/bridge.h>
#include <stdio.h>

using namespace upb;
using namespace upb::googlepb;
using namespace google::protobuf;
using namespace std;

int main(int argc, char **argv) {
    reffed_ptr<MessageDef> def1 = MessageDef::New();
    DefBuilder builder;
    if (argc == 42)
        reffed_ptr<const MessageDef> def2 = builder.GetMessageDef((Descriptor *) NULL);

    printf("1");
}
