#ifndef SPARSE_LLVM_H
#define SPARSE_LLVM_H

#ifndef HAVE_LLVM
struct llfunc {
	int dummy;
};
#else
#include <llvm-c/Core.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Analysis.h>

struct llfunc {
	char		name[256];	/* wasteful */
	LLVMValueRef	func;
};
#endif

#endif
