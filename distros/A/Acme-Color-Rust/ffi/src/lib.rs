use std::cell::Cell;
use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;

struct Color {
    name: String,
    red: u8,
    green: u8,
    blue: u8,
}

impl Color {
    fn new(name: &str, red: u8, green: u8, blue: u8) -> Color {
        Color {
            name: String::from(name),
            red: red,
            green: green,
            blue: blue,
        }
    }

    fn get_name(&self) -> String {
        String::from(self.name.as_str())
    }

    fn get_red(&self) -> u8 {
        self.red
    }

    fn get_green(&self) -> u8 {
        self.green
    }

    fn get_blue(&self) -> u8 {
        self.blue
    }
}

thread_local!(
  static COUNTER: Cell<u32> = Cell::new(0);
  static STORE: RefCell<HashMap<u32, Color>> = RefCell::new(HashMap::new())
);

#[no_mangle]
pub extern "C" fn color_new(name: *const c_char, red: u8, green: u8, blue: u8) -> u32 {
    let name = unsafe { CStr::from_ptr(name) };
    let color = Color::new(name.to_str().unwrap(), red, green, blue);

    let index = COUNTER.with(|it| {
        let index = it.get();
        it.set(index + 1);
        index
    });

    STORE.with(|it| {
        let mut it = it.borrow_mut();
        it.insert(index, color);
    });

    index
}

#[no_mangle]
pub extern "C" fn color_name(index: u32) -> *const c_char {
    thread_local!(
        static KEEP: RefCell<Option<CString>> = RefCell::new(None);
    );

    let name = STORE.with(|it| {
        let it = it.borrow();
        let color = it.get(&index).unwrap();
        color.get_name()
    });

    let name = CString::new(name).unwrap();
    let ptr = name.as_ptr();
    KEEP.with(|k| {
        *k.borrow_mut() = Some(name);
    });
    ptr
}

#[no_mangle]
pub extern "C" fn color_red(index: u32) -> u8 {
    STORE.with(|it| {
        let it = it.borrow();
        let color = it.get(&index).unwrap();
        color.get_red()
    })
}

#[no_mangle]
pub extern "C" fn color_green(index: u32) -> u8 {
    STORE.with(|it| {
        let it = it.borrow();
        let color = it.get(&index).unwrap();
        color.get_green()
    })
}

#[no_mangle]
pub extern "C" fn color_blue(index: u32) -> u8 {
    STORE.with(|it| {
        let it = it.borrow();
        let color = it.get(&index).unwrap();
        color.get_blue()
    })
}

#[no_mangle]
pub extern "C" fn color_DESTROY(index: u32) {
    STORE.with(|it| {
        let mut it = it.borrow_mut();
        it.remove(&index);
    })
}
