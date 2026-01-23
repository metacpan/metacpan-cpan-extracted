/*
 * Acme::ExtUtils::XSOne::Test::Calculator::Memory - Memory and history functions
 *
 * This module accesses the shared state defined in _header.xs
 */

/* Memory package helpers - need access to memory_slots */
static int mem_is_valid_slot(int slot) {
    return (slot >= 0 && slot < MAX_MEMORY_SLOTS);
}

static int mem_get_used_slots(void) {
    int count = 0;
    for (int i = 0; i < MAX_MEMORY_SLOTS; i++) {
        if (memory_slots[i] != 0.0) count++;
    }
    return count;
}

static double mem_sum_all(void) {
    double sum = 0.0;
    for (int i = 0; i < MAX_MEMORY_SLOTS; i++) {
        sum += memory_slots[i];
    }
    return sum;
}

static void mem_add_to_slot(int slot, double value) {
    if (mem_is_valid_slot(slot)) {
        memory_slots[slot] += value;
    }
}

MODULE = Acme::ExtUtils::XSOne::Test::Calculator    PACKAGE = Acme::ExtUtils::XSOne::Test::Calculator::Memory

PROTOTYPES: DISABLE

int
store(slot, value)
    int slot
    double value
CODE:
    RETVAL = store_memory(slot, value);
    if (!RETVAL) {
        warn("Invalid memory slot %d (valid: 0-%d)", slot, MAX_MEMORY_SLOTS - 1);
    }
OUTPUT:
    RETVAL

double
recall(slot)
    int slot
CODE:
    if (slot < 0 || slot >= MAX_MEMORY_SLOTS) {
        warn("Invalid memory slot %d (valid: 0-%d)", slot, MAX_MEMORY_SLOTS - 1);
        RETVAL = 0.0;
    } else {
        RETVAL = recall_memory(slot);
    }
OUTPUT:
    RETVAL

void
clear()
CODE:
    clear_all_memory();

double
ans()
CODE:
    RETVAL = get_last_result();
OUTPUT:
    RETVAL

int
history_count()
CODE:
    RETVAL = history_count;
OUTPUT:
    RETVAL

void
get_history_entry(index)
    int index
PPCODE:
    if (index < 0 || index >= history_count) {
        croak("Invalid history index %d (valid: 0-%d)", index, history_count - 1);
    }
    EXTEND(SP, 4);
    PUSHs(sv_2mortal(newSVpvf("%c", history[index].operation)));
    PUSHs(sv_2mortal(newSVnv(history[index].operand1)));
    PUSHs(sv_2mortal(newSVnv(history[index].operand2)));
    PUSHs(sv_2mortal(newSVnv(history[index].result)));

int
max_memory_slots()
CODE:
    RETVAL = MAX_MEMORY_SLOTS;
OUTPUT:
    RETVAL

int
max_history_entries()
CODE:
    RETVAL = MAX_HISTORY;
OUTPUT:
    RETVAL

int
is_valid_slot(slot)
    int slot
CODE:
    RETVAL = mem_is_valid_slot(slot);
OUTPUT:
    RETVAL

int
used_slots()
CODE:
    RETVAL = mem_get_used_slots();
OUTPUT:
    RETVAL

double
sum_all_slots()
CODE:
    RETVAL = mem_sum_all();
OUTPUT:
    RETVAL

void
add_to(slot, value)
    int slot
    double value
CODE:
    mem_add_to_slot(slot, value);

void
import(...)
CODE:
{
    static const char *memory_exports[] = {
        "store", "recall", "clear", "ans",
        "history_count", "get_history_entry",
        "max_memory_slots", "max_history_entries",
        "is_valid_slot", "used_slots", "sum_all_slots", "add_to"
    };
    do_import(aTHX_ "Acme::ExtUtils::XSOne::Test::Calculator::Memory",
              memory_exports, 12, items, ax);
}
