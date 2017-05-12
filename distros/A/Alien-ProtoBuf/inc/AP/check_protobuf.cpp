#include <google/protobuf/compiler/importer.h>
#include <stdio.h>

using namespace google::protobuf::compiler;
using namespace std;

class CollectErrors : public MultiFileErrorCollector {
    virtual void AddError(const string &filename, int line, int column, const string &message) {
        // dummy
    }
};

int main(int argc, char **argv) {
    CollectErrors collector;
    DiskSourceTree source_tree;
    Importer importer(&source_tree, &collector);

    printf("%d", GOOGLE_PROTOBUF_VERSION);
}
