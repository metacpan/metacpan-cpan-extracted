#[no_mangle]
pub extern "C" fn add(left: usize, right: usize) -> usize {
    left + right
}

//~ https://doc.rust-lang.org/nomicon/ffi.html
pub extern "C" fn r#mod(x: i32, y: i32) -> i32 {
    x % y
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
