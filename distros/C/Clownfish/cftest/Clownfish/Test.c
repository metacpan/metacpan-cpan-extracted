/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define CFISH_USE_SHORT_NAMES
#define TESTCFISH_USE_SHORT_NAMES

#include "Clownfish/Test.h"

#include "Clownfish/TestHarness/TestBatch.h"
#include "Clownfish/TestHarness/TestSuite.h"

#include "Clownfish/Test/TestBlob.h"
#include "Clownfish/Test/TestBoolean.h"
#include "Clownfish/Test/TestByteBuf.h"
#include "Clownfish/Test/TestString.h"
#include "Clownfish/Test/TestCharBuf.h"
#include "Clownfish/Test/TestClass.h"
#include "Clownfish/Test/TestErr.h"
#include "Clownfish/Test/TestHash.h"
#include "Clownfish/Test/TestHashIterator.h"
#include "Clownfish/Test/TestLockFreeRegistry.h"
#include "Clownfish/Test/TestMethod.h"
#include "Clownfish/Test/TestNum.h"
#include "Clownfish/Test/TestObj.h"
#include "Clownfish/Test/TestPtrHash.h"
#include "Clownfish/Test/TestVector.h"
#include "Clownfish/Test/Util/TestAtomic.h"
#include "Clownfish/Test/Util/TestMemory.h"

TestSuite*
Test_create_test_suite() {
    TestSuite *suite = TestSuite_new();

    TestSuite_Add_Batch(suite, (TestBatch*)TestClass_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestMethod_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestVector_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestHash_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestHashIterator_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestObj_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestErr_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestBlob_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestBB_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestStr_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestCB_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestBoolean_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestNum_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestAtomic_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestLFReg_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestMemory_new());
    TestSuite_Add_Batch(suite, (TestBatch*)TestPtrHash_new());

    return suite;
}


